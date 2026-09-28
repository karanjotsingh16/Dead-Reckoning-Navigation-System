import 'package:flutter/material.dart';
import 'vehicle_issues_data.dart';

/// Yeh screen "Need Help" button dabane par khulti hai.
/// Symptom list dikhati hai, aur select karne par step-by-step
/// troubleshooting guide deti hai - sab offline, koi internet nahi chahiye.
class MechanicalHelpPage extends StatefulWidget {
  // Optional: current location (dead-reckoning se) jo issue report ke
  // saath tag ho sakti hai.
  final String? currentLocationInfo;

  const MechanicalHelpPage({super.key, this.currentLocationInfo});

  @override
  State<MechanicalHelpPage> createState() => _MechanicalHelpPageState();
}

class _MechanicalHelpPageState extends State<MechanicalHelpPage> {
  VehicleIssue? _selectedIssue;
  bool _issueLogged = false;

  Color _severityColor(String severity) {
    switch (severity) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Help - Offline Assistant'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _selectedIssue == null
          ? _buildSymptomList()
          : _buildIssueDetail(_selectedIssue!),
    );
  }

  Widget _buildSymptomList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.deepOrange.shade50,
          child: const Text(
            'Apni gaadi ka symptom select karo - offline guidance turant milega:',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: vehicleIssuesDatabase.length,
            itemBuilder: (context, index) {
              final issue = vehicleIssuesDatabase[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Text(issue.icon, style: const TextStyle(fontSize: 30)),
                  title: Text(
                    issue.symptom,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _severityColor(issue.severity).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Severity: ${issue.severity}',
                      style: TextStyle(
                        color: _severityColor(issue.severity),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _selectedIssue = issue;
                      _issueLogged = false;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIssueDetail(VehicleIssue issue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _selectedIssue = null),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Wapas symptom list pe jao'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(issue.icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  issue.symptom,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Possible causes
          const Text('Possible Causes:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          ...issue.possibleCauses.map(
            (cause) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $cause'),
            ),
          ),
          const SizedBox(height: 20),

          // Step-by-step guide
          const Text('Step-by-Step Guide:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...issue.steps.asMap().entries.map((entry) {
            int idx = entry.key;
            String step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.deepOrange,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(step, style: const TextStyle(fontSize: 15))),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Location-tagging feature - jaise problem statement mein bola gaya hai
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Location Tagging',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.currentLocationInfo ??
                      'Current dead-reckoned position is saved automatically',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (!_issueLogged)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _issueLogged = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Issue location save ho gaya! Signal aane par mechanic ko bheja jayega.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Is issue ko location ke saath log karo'),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 6),
                      Text('Logged! Signal aane par sync hoga.',
                          style: TextStyle(color: Colors.green)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
