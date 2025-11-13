import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'sidebar.dart';
import 'user_provider.dart';
// import 'email_page.dart';
import 'message.dart';
import 'audio_call_page.dart';

class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  EmployeeDirectoryPageState createState() => EmployeeDirectoryPageState();
}

class EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  List<dynamic> employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final response = await http.get(
        Uri.parse("https://sabari2602.onrender.com/api/employees"),
      );

      if (response.statusCode == 200) {
        setState(() {
          employees = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        print("❌ Failed to load employees: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("❌ Error fetching employees: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Employee Directory',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search + Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _searchBox('Search employee...', 200),
                ElevatedButton(
                  onPressed: fetchEmployees, // 🔄 refresh from DB
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "EmployeeList",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ Loader or Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      itemCount: employees.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                      itemBuilder: (context, index) {
                        final emp = employees[index];
                        //final profile = emp['photo']; // 🔹 backend field
                        final imageUrl =
                            (emp['employeeImage'] != null &&
                                emp['employeeImage'].isNotEmpty)
                            ? "https://sabari2602.onrender.com${emp['employeeImage']}"
                            : "";
                        return _employeeCard(
                          emp['employeeId'] ?? "", // ✅ pass employeeId also
                          emp['employeeName'] ?? "Unknown",
                          emp['position'] ?? "Unknown",
                          // "http://localhost:5000/uploads/${emp['photo']}", // 🔴 profile image URL
                          imageUrl, // 🔹 safe URL or empty
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Employee Card
  Widget _employeeCard(
    String employeeId,
    String name,
    String role,
    String imageUrl,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : const AssetImage("assets/profile.png"),
              //backgroundImage: NetworkImage(imageUrl),
              onBackgroundImageError: (_, __) {
                debugPrint('Image load error for $imageUrl');
              },
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              role,
              style: const TextStyle(fontSize: 15.5, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.email,
                    size: 25,
                    color: Colors.deepPurple.withOpacity(0.5),
                  ),
                  onPressed: null,
                  //,
                  // onPressed: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => EmailPage(
                  //         employeeId: employeeId, // ✅ now correct
                  //       ),
                  //     ),
                  //   );
                  // },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.message,
                    size: 25,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MsgPage(
                          employeeId: employeeId, // ✅ new message page
                        ),
                      ),
                    );
                  },
                ),

                //Icon(Icons.message, size: 25, color: Colors.deepPurple),
                IconButton(
                  icon: const Icon(
                    Icons.phone,
                    size: 25,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () {
                    // TODO: replace with your logged-in employee id retrieval
                    //  const currentUserId = "EMPID"; // <<--- get from Provider / auth
                    final currentUserId = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).employeeId!;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AudioCallPage(
                          currentUserId: currentUserId,
                          targetUserId: employeeId,
                          isCaller: true,
                          isVideo: false,
                        ),
                      ),
                    );
                  },
                ),

                IconButton(
                  icon: const Icon(
                    Icons.video_call,
                    size: 25,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () {
                    // TODO: replace with your logged-in employee id retrieval
                    //const currentUserId = "EMPID"; // <<--- get from Provider / auth
                    final currentUserId = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).employeeId!;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AudioCallPage(
                          currentUserId: currentUserId,
                          targetUserId: employeeId,
                          isCaller: true,
                          isVideo: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Search Box
  Widget _searchBox(String hint, double width) {
    return SizedBox(
      width: width,
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF2D2F41),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
