import 'package:flutter/material.dart'; // Core Flutter UI components
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management library
import 'package:fl_chart/fl_chart.dart'; // Chart rendering library
import 'package:intl/intl.dart'; // Formats dates for chart labels
import 'package:mbap_project/models/study_task.dart'; // Defines the Firestore task data
import 'package:mbap_project/providers/firebase_provider.dart'; // Provides the Firestore task stream
import 'package:mbap_project/providers/theme_provider.dart'; // Application theme colours
import 'dart:ui' as ui; // Provides image encoding utilities
import 'dart:typed_data'; // Provides Uint8List for raw byte data
import 'package:flutter/rendering.dart'; // Provides RenderRepaintBoundary for chart capture
import 'package:pdf/pdf.dart'; // PDF colour and page format constants
import 'package:pdf/widgets.dart' as pw; // PDF widget library for building pages
import 'package:printing/printing.dart'; // Opens the system print and share dialog

// Displays study analytics charts for the signed-in user.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

// Holds the chart capture keys and export state.
class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  // Keys for capturing each chart widget as a PNG image.
  final _completionChartKey = GlobalKey();
  final _hoursChartKey = GlobalKey();
  final _tagChartKey = GlobalKey();
  final _priorityChartKey = GlobalKey();

  bool _isExporting = false; // Tracks whether the PDF export is in progress

  // Groups tasks by their start date (ignoring the time component).
  Map<DateTime, List<StudyTask>> _groupByDate(List<StudyTask> tasks) {
    final Map<DateTime, List<StudyTask>> grouped = {}; // Stores tasks keyed by date

    for (final task in tasks) {
      // Strips the time so tasks on the same day share one key.
      final dateKey = DateTime(
        task.startDate.year,
        task.startDate.month,
        task.startDate.day,
      ); // Creates a date-only key

      // Adds the task to its matching date bucket.
      grouped.putIfAbsent(dateKey, () => []).add(task); // Appends the task to the list
    }

    return grouped; // Returns the date-grouped task map
  }

  // Builds the last 7 days in order for the chart x-axis.
  List<DateTime> _lastSevenDays() {
    final now = DateTime.now(); // Reads the current date
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i)); // Counts backwards from today
      return DateTime(date.year, date.month, date.day); // Strips the time component
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider); // Rebuilds when the colour scheme changes

    // Watches the Firestore task stream for real-time task updates.
    final tasks = ref.watch(tasksProvider); // Uses the same stream as other screens

    return Scaffold(
      backgroundColor: blackColour, // Matches the main app background
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0), // Adds space around the header
              child: Row(
                children: [
                  // Returns to the dashboard when tapped.
                  IconButton(
                    onPressed: () => Navigator.pop(context), // Closes the analytics screen
                    icon: Icon(Icons.arrow_back, color: textPrimaryColour), // Displays the back arrow
                  ),
                  Text(
                    'Study Analytics', // Sets the screen title
                    style: TextStyle(
                      color: textPrimaryColour, // Sets the white text colour
                      fontSize: 26, // Sets the title size
                      fontWeight: FontWeight.bold, // Makes the title bold
                    ),
                  ),

                  const Spacer(), // Pushes the export button to the right

                  // Opens the PDF export preview when tapped.
                  IconButton(
                    onPressed: _isExporting ? null : _exportPdf, // Disables while exporting
                    icon: _isExporting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColour,
                            ),
                          )
                        : Icon(Icons.picture_as_pdf_rounded, color: accentColour), // PDF icon
                  ),
                ],
              ),
            ),

            // --- DIVIDER ---
            Divider(color: dividerColour), // Separates the header from the content

            // --- CHART CONTENT ---
            Expanded(
              child: tasks.when(
                // Builds the charts after the task stream delivers data.
                data: (taskList) {
                  final days = _lastSevenDays(); // Gets the last 7 calendar days
                  final grouped = _groupByDate(taskList); // Groups all tasks by date

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), // Adds space around the charts
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Aligns titles to the left
                      children: [
                        // --- COMPLETION RATE CHART ---
                        _buildSectionTitle('Completion Rate (Last 7 Days)'), // Displays the chart heading
                        const SizedBox(height: 8), // Adds space below the heading
                        _buildSubtitle('Percentage of tasks completed each day'), // Displays the description
                        const SizedBox(height: 16), // Adds space before the chart
                        RepaintBoundary(key: _completionChartKey, child: _buildCompletionChart(days, grouped)), // Renders the completion bar chart

                        const SizedBox(height: 40), // Adds space between charts

                        // --- STUDY HOURS CHART ---
                        _buildSectionTitle('Study Hours (Last 7 Days)'), // Displays the chart heading
                        const SizedBox(height: 8), // Adds space below the heading
                        _buildSubtitle('Total planned study time each day'), // Displays the description
                        const SizedBox(height: 16), // Adds space before the chart
                        RepaintBoundary(key: _hoursChartKey, child: _buildStudyHoursChart(days, grouped)), // Renders the study hours bar chart

                        const SizedBox(height: 40), // Adds space between charts

                        // --- TASKS BY TAG CHART ---
                        _buildSectionTitle('Tasks by Tag'), // Displays the chart heading
                        const SizedBox(height: 8), // Adds space below the heading
                        _buildSubtitle('Distribution of all tasks across tags'), // Displays the description
                        const SizedBox(height: 16), // Adds space before the chart
                        RepaintBoundary(key: _tagChartKey, child: _buildTagPieChart(taskList)), // Renders the tag pie chart

                        const SizedBox(height: 40), // Adds space between charts

                        // --- TASKS BY PRIORITY CHART ---
                        _buildSectionTitle('Tasks by Priority'), // Displays the chart heading
                        const SizedBox(height: 8), // Adds space below the heading
                        _buildSubtitle('Distribution of all tasks across priority levels'), // Displays the description
                        const SizedBox(height: 16), // Adds space before the chart
                        RepaintBoundary(key: _priorityChartKey, child: _buildPriorityPieChart(taskList)), // Renders the priority pie chart

                        const SizedBox(height: 50), // Adds space at the bottom
                      ],
                    ),
                  );
                },

                // Shows a progress indicator while the task stream is loading.
                loading: () => const Center(child: CircularProgressIndicator()),

                // Shows an error message when the task stream fails.
                error: (_, _) => Center(
                  child: Text(
                    'Unable to load analytics.',
                    style: TextStyle(color: textSecondaryColour),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Captures a chart widget as a PNG byte array using its RepaintBoundary key.
  Future<Uint8List?> _captureChart(GlobalKey key) async {
    // Finds the RenderRepaintBoundary attached to the given key.
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null; // Returns null when the widget is not rendered

    // Converts the widget to a high-resolution image.
    final image = await boundary.toImage(pixelRatio: 3.0); // 3x resolution for sharp output
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png); // Encodes as PNG
    return byteData?.buffer.asUint8List(); // Returns the raw PNG bytes
  }

  // Captures all four charts and builds a PDF document for sharing.
  Future<void> _exportPdf() async {
    setState(() => _isExporting = true); // Shows the loading spinner

    try {
      // Captures each chart as a PNG image.
      final completionImage = await _captureChart(_completionChartKey);
      final hoursImage = await _captureChart(_hoursChartKey);
      final tagImage = await _captureChart(_tagChartKey);
      final priorityImage = await _captureChart(_priorityChartKey);

      // Creates a new PDF document.
      final pdf = pw.Document();

      // Formats today's date for the report header.
      final dateString = DateFormat('d MMMM yyyy').format(DateTime.now()); // e.g. 8 August 2026

      // Builds a helper that adds one chart per page.
      void addChartPage(String title, String subtitle, Uint8List? image) {
        if (image == null) return; // Skips charts that failed to capture
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4, // Uses A4 paper size
            margin: const pw.EdgeInsets.all(24), // Tighter margins for more chart space
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start, // Aligns text to the left
              children: [
                pw.Text(
                  title, // Displays the chart heading
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  subtitle, // Displays the chart description
                  style: const pw.TextStyle(fontSize: 20, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 16),
                pw.Expanded(
                  child: pw.FittedBox(
                    fit: pw.BoxFit.contain, // Scales the image to fit the remaining space
                    alignment: pw.Alignment.topCenter, // Anchors the image to the top
                    child: pw.Image(pw.MemoryImage(image)), // Embeds the chart image
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // --- TITLE PAGE ---
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center, // Centres the title vertically
            children: [
              pw.Text(
                'Study Analytics Report',
                style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Generated on $dateString',
                style: const pw.TextStyle(fontSize: 24, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      );

      // --- ONE PAGE PER CHART ---
      addChartPage('Completion Rate (Last 7 Days)', 'Percentage of tasks completed each day', completionImage);
      addChartPage('Study Hours (Last 7 Days)', 'Total planned study time each day', hoursImage);
      addChartPage('Tasks by Tag', 'Distribution of all tasks across tags', tagImage);
      addChartPage('Tasks by Priority', 'Distribution of all tasks across priority levels', priorityImage);

      // Opens the system print preview with save and share options.
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(), // Passes the built PDF to the preview
        name: 'StudyBuddy_Analytics_$dateString', // Sets the default file name
      );
    } catch (e) {
      // Shows an error message when the export fails.
      if (!mounted) return; // Guards against calling setState after disposal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false); // Hides the loading spinner
    }
  }

  // Builds the bold heading above each chart.
  Widget _buildSectionTitle(String text) {
    return Text(
      text, // Displays the section heading
      style: TextStyle(
        color: textPrimaryColour, // Sets the white text colour
        fontSize: 20, // Sets the heading size
        fontWeight: FontWeight.bold, // Makes the heading bold
      ),
    );
  }

  // Builds the description text below each heading.
  Widget _buildSubtitle(String text) {
    return Text(
      text, // Displays the description
      style: TextStyle(
        color: textSecondaryColour, // Sets the muted text colour
        fontSize: 15, // Sets the description size
      ),
    );
  }

  // --- COMPLETION RATE BAR CHART ---
  // Shows the percentage of tasks completed for each of the last 7 days.
  Widget _buildCompletionChart(
    List<DateTime> days,
    Map<DateTime, List<StudyTask>> grouped,
  ) {
    // Calculates the completion percentage for each day.
    final rates = days.map((day) {
      final dayTasks = grouped[day] ?? []; // Gets the tasks for this day
      if (dayTasks.isEmpty) return 0.0; // Returns zero when there are no tasks
      final completed = dayTasks.where((t) => t.isCompleted).length; // Counts completed tasks
      return (completed / dayTasks.length) * 100; // Converts to a percentage
    }).toList();

    return Container(
      height: 220, // Sets the chart height
      padding: const EdgeInsets.all(16), // Adds space inside the container
      decoration: BoxDecoration(
        color: darkGreyColour, // Sets the dark grey background
        borderRadius: BorderRadius.circular(16), // Rounds the container corners
        border: Border.all(color: borderColour), // Adds a subtle border
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround, // Spreads the bars evenly
          maxY: 100, // Caps the y-axis at 100%
          barTouchData: BarTouchData(
            // Configures the tooltip shown when a bar is tapped.
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(8), // Rounds the tooltip corners
              getTooltipColor: (_) => darkGreyColour, // Sets the tooltip background
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()}%', // Displays the percentage value
                  TextStyle(
                    color: accentColour, // Sets the accent text colour
                    fontWeight: FontWeight.bold, // Makes the value bold
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            // Hides the top and right axis labels.
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // Shows the day abbreviation below each bar.
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // Displays the bottom labels
                getTitlesWidget: (value, meta) {
                  final index = value.toInt(); // Converts the position to an index
                  if (index < 0 || index >= days.length) return const SizedBox.shrink(); // Hides invalid labels
                  return Padding(
                    padding: const EdgeInsets.only(top: 8), // Adds space above the label
                    child: Text(
                      DateFormat('E').format(days[index]), // Shows the day abbreviation (Mon, Tue, etc.)
                      style: TextStyle(
                        color: textSecondaryColour, // Sets the muted text colour
                        fontSize: 13, // Sets the label size
                      ),
                    ),
                  );
                },
              ),
            ),
            // Shows percentage labels on the left axis.
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // Displays the left labels
                reservedSize: 36, // Reserves space for the labels
                interval: 25, // Shows labels at 0%, 25%, 50%, 75%, 100%
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%', // Displays the percentage label
                    style: TextStyle(
                      color: textSecondaryColour, // Sets the muted text colour
                      fontSize: 13, // Sets the label size
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true, // Displays the horizontal grid lines
            drawVerticalLine: false, // Hides the vertical grid lines
            horizontalInterval: 25, // Draws a line every 25%
            getDrawingHorizontalLine: (value) => FlLine(
              color: borderColour, // Sets the grid line colour
              strokeWidth: 1, // Sets the grid line thickness
            ),
          ),
          borderData: FlBorderData(show: false), // Hides the chart border
          // Builds one bar for each of the last 7 days.
          barGroups: List.generate(days.length, (i) {
            return BarChartGroupData(
              x: i, // Sets the bar position
              barRods: [
                BarChartRodData(
                  toY: rates[i], // Sets the bar height to the completion percentage
                  color: highlightColour, // Uses the highlight colour for the bar
                  width: 18, // Sets the bar width
                  borderRadius: BorderRadius.circular(6), // Rounds the bar top
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true, // Shows the background track behind the bar
                    toY: 100, // Extends the track to the full height
                    color: borderColour, // Sets the track colour
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- STUDY HOURS BAR CHART ---
  // Shows the total planned study time for each of the last 7 days.
  Widget _buildStudyHoursChart(
    List<DateTime> days,
    Map<DateTime, List<StudyTask>> grouped,
  ) {
    // Calculates the total study hours for each day.
    final hours = days.map((day) {
      final dayTasks = grouped[day] ?? []; // Gets the tasks for this day
      double totalMinutes = 0; // Starts the total at zero

      for (final task in dayTasks) {
        // Adds the duration of each task in minutes.
        totalMinutes += task.endDate.difference(task.startDate).inMinutes; // Sums the task duration
      }

      return totalMinutes / 60; // Converts minutes to hours
    }).toList();

    // Finds the tallest bar so the y-axis scales properly.
    final maxHours = hours.reduce((a, b) => a > b ? a : b); // Gets the highest value
    final yMax = maxHours < 1 ? 1.0 : (maxHours * 1.2).ceilToDouble(); // Adds 20% headroom

    return Container(
      height: 220, // Sets the chart height
      padding: const EdgeInsets.all(16), // Adds space inside the container
      decoration: BoxDecoration(
        color: darkGreyColour, // Sets the dark grey background
        borderRadius: BorderRadius.circular(16), // Rounds the container corners
        border: Border.all(color: borderColour), // Adds a subtle border
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround, // Spreads the bars evenly
          maxY: yMax, // Sets the y-axis maximum
          barTouchData: BarTouchData(
            // Configures the tooltip shown when a bar is tapped.
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(8), // Rounds the tooltip corners
              getTooltipColor: (_) => darkGreyColour, // Sets the tooltip background
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)}h', // Displays the hours value
                  TextStyle(
                    color: accentColour, // Sets the accent text colour
                    fontWeight: FontWeight.bold, // Makes the value bold
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            // Hides the top and right axis labels.
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            // Shows the day abbreviation below each bar.
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // Displays the bottom labels
                getTitlesWidget: (value, meta) {
                  final index = value.toInt(); // Converts the position to an index
                  if (index < 0 || index >= days.length) return const SizedBox.shrink(); // Hides invalid labels
                  return Padding(
                    padding: const EdgeInsets.only(top: 8), // Adds space above the label
                    child: Text(
                      DateFormat('E').format(days[index]), // Shows the day abbreviation
                      style: TextStyle(
                        color: textSecondaryColour, // Sets the muted text colour
                        fontSize: 13, // Sets the label size
                      ),
                    ),
                  );
                },
              ),
            ),
            // Shows hour labels on the left axis.
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // Displays the left labels
                reservedSize: 36, // Reserves space for the labels
                interval: yMax / 4, // Divides the axis into 4 intervals
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(1)}h', // Displays the hours label
                    style: TextStyle(
                      color: textSecondaryColour, // Sets the muted text colour
                      fontSize: 13, // Sets the label size
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true, // Displays the horizontal grid lines
            drawVerticalLine: false, // Hides the vertical grid lines
            horizontalInterval: yMax / 4, // Matches the left axis interval
            getDrawingHorizontalLine: (value) => FlLine(
              color: borderColour, // Sets the grid line colour
              strokeWidth: 1, // Sets the grid line thickness
            ),
          ),
          borderData: FlBorderData(show: false), // Hides the chart border
          // Builds one bar for each of the last 7 days.
          barGroups: List.generate(days.length, (i) {
            return BarChartGroupData(
              x: i, // Sets the bar position
              barRods: [
                BarChartRodData(
                  toY: hours[i], // Sets the bar height to the study hours
                  color: accentColour, // Uses the accent colour for the bar
                  width: 18, // Sets the bar width
                  borderRadius: BorderRadius.circular(6), // Rounds the bar top
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- TAG PIE CHART ---
  // Shows the distribution of all tasks across their assigned tags.
  Widget _buildTagPieChart(List<StudyTask> tasks) {
    // Counts how many tasks belong to each tag.
    final Map<String, int> tagCounts = {}; // Stores the tag name and count

    for (final task in tasks) {
      final tag = (task.tagName == null || task.tagName!.isEmpty) ? 'No Tag' : task.tagName!; // Falls back to 'No Tag' for untagged tasks
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1; // Increments the count for this tag
    }

    // Returns a message when there are no tasks to chart.
    if (tagCounts.isEmpty) {
      return _buildEmptyChartMessage('No tasks to display.'); // Shows the empty state
    }

    // Assigns a colour to each tag section.
    final colours = [
      highlightColour, // First colour
      accentColour, // Second colour
      Colors.tealAccent, // Third colour
      Colors.purpleAccent, // Fourth colour
      Colors.orangeAccent, // Fifth colour
      Colors.cyanAccent, // Sixth colour
      Colors.pinkAccent, // Seventh colour
      Colors.limeAccent, // Eighth colour
    ];

    final entries = tagCounts.entries.toList(); // Converts the map to a list of entries

    return Container(
      padding: const EdgeInsets.all(16), // Adds space inside the container
      decoration: BoxDecoration(
        color: darkGreyColour, // Sets the dark grey background
        borderRadius: BorderRadius.circular(16), // Rounds the container corners
        border: Border.all(color: borderColour), // Adds a subtle border
      ),
      child: Column(
        children: [
          // Renders the pie chart.
          SizedBox(
            height: 200, // Sets the chart height
            child: PieChart(
              PieChartData(
                sectionsSpace: 2, // Adds a gap between sections
                centerSpaceRadius: 40, // Creates a donut hole in the centre
                // Builds one section for each tag.
                sections: List.generate(entries.length, (i) {
                  return PieChartSectionData(
                    value: entries[i].value.toDouble(), // Sets the section size
                    color: colours[i % colours.length], // Cycles through the colour list
                    radius: 50, // Sets the section thickness
                    title: '${entries[i].value}', // Displays the task count inside the section
                    titleStyle: TextStyle(
                      color: blackColour, // Sets the dark text colour
                      fontSize: 13, // Sets the label size
                      fontWeight: FontWeight.bold, // Makes the label bold
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 16), // Adds space between the chart and the legend

          // Builds the colour legend below the pie chart.
          Wrap(
            spacing: 16, // Adds horizontal space between legend items
            runSpacing: 8, // Adds vertical space between wrapped rows
            children: List.generate(entries.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min, // Shrinks the row to fit its content
                children: [
                  Container(
                    width: 12, // Sets the colour dot width
                    height: 12, // Sets the colour dot height
                    decoration: BoxDecoration(
                      color: colours[i % colours.length], // Matches the pie section colour
                      shape: BoxShape.circle, // Makes the dot circular
                    ),
                  ),
                  const SizedBox(width: 6), // Adds space between the dot and the label
                  Text(
                    entries[i].key, // Displays the tag name
                    style: TextStyle(
                      color: textSecondaryColour, // Sets the muted text colour
                      fontSize: 14, // Sets the label size
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- PRIORITY PIE CHART ---
  // Shows the distribution of all tasks across priority levels.
  Widget _buildPriorityPieChart(List<StudyTask> tasks) {
    // Counts how many tasks belong to each priority level.
    int low = 0; // Stores the low priority count
    int medium = 0; // Stores the medium priority count
    int high = 0; // Stores the high priority count

    for (final task in tasks) {
      switch (task.priority) {
        case 1:
          low++; // Increments the low priority count
          break;
        case 2:
          medium++; // Increments the medium priority count
          break;
        case 3:
          high++; // Increments the high priority count
          break;
      }
    }

    // Returns a message when there are no tasks to chart.
    if (tasks.isEmpty) {
      return _buildEmptyChartMessage('No tasks to display.'); // Shows the empty state
    }

    // Maps priority labels and counts to their display colours.
    final data = [
      {'label': 'Low', 'value': low, 'colour': Colors.greenAccent},
      {'label': 'Medium', 'value': medium, 'colour': Colors.orangeAccent},
      {'label': 'High', 'value': high, 'colour': Colors.redAccent},
    ];

    return Container(
      padding: const EdgeInsets.all(16), // Adds space inside the container
      decoration: BoxDecoration(
        color: darkGreyColour, // Sets the dark grey background
        borderRadius: BorderRadius.circular(16), // Rounds the container corners
        border: Border.all(color: borderColour), // Adds a subtle border
      ),
      child: Column(
        children: [
          // Renders the pie chart.
          SizedBox(
            height: 200, // Sets the chart height
            child: PieChart(
              PieChartData(
                sectionsSpace: 2, // Adds a gap between sections
                centerSpaceRadius: 40, // Creates a donut hole in the centre
                // Builds one section for each priority level.
                sections: data.map((entry) {
                  final value = entry['value'] as int; // Reads the task count
                  return PieChartSectionData(
                    value: value.toDouble(), // Sets the section size
                    color: entry['colour'] as Color, // Sets the section colour
                    radius: 50, // Sets the section thickness
                    title: '$value', // Displays the task count inside the section
                    titleStyle: TextStyle(
                      color: blackColour, // Sets the dark text colour
                      fontSize: 13, // Sets the label size
                      fontWeight: FontWeight.bold, // Makes the label bold
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16), // Adds space between the chart and the legend

          // Builds the colour legend below the pie chart.
          Wrap(
            spacing: 16, // Adds horizontal space between legend items
            runSpacing: 8, // Adds vertical space between wrapped rows
            children: data.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min, // Shrinks the row to fit its content
                children: [
                  Container(
                    width: 12, // Sets the colour dot width
                    height: 12, // Sets the colour dot height
                    decoration: BoxDecoration(
                      color: entry['colour'] as Color, // Matches the pie section colour
                      shape: BoxShape.circle, // Makes the dot circular
                    ),
                  ),
                  const SizedBox(width: 6), // Adds space between the dot and the label
                  Text(
                    entry['label'] as String, // Displays the priority label
                    style: TextStyle(
                      color: textSecondaryColour, // Sets the muted text colour
                      fontSize: 14, // Sets the label size
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Shows a centred message when no data is available for a chart.
  Widget _buildEmptyChartMessage(String message) {
    return Container(
      height: 150, // Sets the placeholder height
      decoration: BoxDecoration(
        color: darkGreyColour, // Sets the dark grey background
        borderRadius: BorderRadius.circular(16), // Rounds the container corners
        border: Border.all(color: borderColour), // Adds a subtle border
      ),
      child: Center(
        child: Text(
          message, // Displays the empty state message
          style: TextStyle(color: textSecondaryColour, fontSize: 15), // Sets the text style
        ),
      ),
    );
  }
}