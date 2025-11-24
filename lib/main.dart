import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

// --- MANDATED GLOBAL VARIABLES (FOR FIREBASE SETUP) ---
const String __app_id = 'community-birth-reg';
const String __firebase_config =
    '{"apiKey": "dummy-key", "projectId": "dummy-project"}';
const String __initial_auth_token = 'dummy-auth-token';

// --- CONFIGURATION CONSTANTS & STYLING ---
const Color primaryColor = Color(0xFF007A5A); // Deep Green
const Color secondaryColor = Color(0xFFE8C668); // Gold/Yellow Accent
const TextStyle kTitleStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: primaryColor,
);
const TextStyle kLabelStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: Colors.black87,
);

// Global instance to manage simulated data across the app
final SimulatedData _simulatedData = SimulatedData();

class SimulatedData {
  // Use a StreamController initialized with the current list to ensure the latest value is available upon subscription.
  late final StreamController<List<BirthRecord>> _pendingRecordsController;

  // Local list to hold records
  final List<BirthRecord> _pendingRecords = [
    // Initial hardcoded records for demonstration (updated with DOB/place/coords)
    BirthRecord(
      id: 'P-12345',
      vhwId: 'vhw_sarah',
      motherName: 'Aisha Musa',
      motherAge: 25,
      gravida: 3,
      parity: 2,
      ancBooked: true,
      ancFacility: 'Rural Clinic A',
      gestationWeeks: 40,
      childName: 'Baby Boy',
      gender: 'Male',
      weight: 3.2,
      isConfirmed: false,
      confirmationId: null,
      dob: '2025-11-01',
      placeOfBirth: 'Rural Clinic A',
      latitude: -17.825, // example coordinates
      longitude: 31.049,
    ),
    BirthRecord(
      id: 'P-67890',
      vhwId: 'vhw_john',
      motherName: 'Binta Kalu',
      motherAge: 32,
      gravida: 1,
      parity: 0,
      ancBooked: false,
      ancFacility: null,
      gestationWeeks: 38,
      childName: 'Baby Girl',
      gender: 'Female',
      weight: 2.9,
      isConfirmed: false,
      confirmationId: null,
      dob: '2025-10-18',
      placeOfBirth: 'Home',
      latitude: -17.820,
      longitude: 31.058,
    ),
  ];

  // Getter for the stream
  Stream<List<BirthRecord>> get pendingRecordsStream =>
      _pendingRecordsController.stream;

  SimulatedData() {
    // Initialize the controller and immediately add the current list as the first event.
    _pendingRecordsController = StreamController.broadcast(
      onListen: () {
        _pendingRecordsController.add(List.from(_pendingRecords));
      },
    );
  }

  void addPendingRecord(BirthRecord record) {
    _pendingRecords.add(record);
    // Publish the updated list to all listeners (Village Head Screen)
    _pendingRecordsController.add(List.from(_pendingRecords));
  }

  void removePendingRecord(String id) {
    _pendingRecords.removeWhere((r) => r.id == id);
    // Publish the updated list
    _pendingRecordsController.add(List.from(_pendingRecords));
  }

  // Synchronous snapshot of pending records (useful for duplicate checks)
  List<BirthRecord> getPendingRecordsSync() => List.from(_pendingRecords);
}

class FireStoreService {
  final String appId;
  final String userId;

  FireStoreService(this.appId, this.userId);

  // Firestore path constants (conceptual)
  String get _pendingCollectionPath =>
      'artifacts/$appId/public/data/birth_records_pending';

  // Simulates Firebase submission (VHW)
  Future<String> submitNewBirth(BirthRecord record) async {
    print('--- Firestore ACTION ---');
    print('Submitting VHW Record to: $_pendingCollectionPath');

    await Future.delayed(const Duration(seconds: 1));
    final newId = 'P-${DateTime.now().millisecondsSinceEpoch}';

    final recordWithId = BirthRecord(
      id: newId,
      vhwId: record.vhwId,
      motherName: record.motherName,
      motherAge: record.motherAge,
      gravida: record.gravida,
      parity: record.parity,
      ancBooked: record.ancBooked,
      ancFacility: record.ancFacility,
      gestationWeeks: record.gestationWeeks,
      childName: record.childName,
      gender: record.gender,
      weight: record.weight,
      dob: record.dob,
      placeOfBirth: record.placeOfBirth,
      latitude: record.latitude,
      longitude: record.longitude,
    );

    _simulatedData.addPendingRecord(recordWithId);

    print(
      'SUCCESS: Record submitted with temp ID $newId, awaiting confirmation.',
    );
    return newId;
  }

  // FIX: Just return the stream, the SimulatedData class handles the initial snapshot.
  Stream<List<BirthRecord>> streamPendingRecords() {
    print('--- Firestore ACTION ---');
    print('Streaming pending records from internal simulation...');

    return _simulatedData.pendingRecordsStream;
  }

  // Simulates Confirmation (Village Head)
  Future<String> confirmBirth(BirthRecord record) async {
    final confirmationId =
        'BR-${DateTime.now().year}-${record.id.split('-').last}';

    print('--- Firestore ACTION ---');
    print('CONFIRMING Record ID: ${record.id}');
    await Future.delayed(const Duration(seconds: 1));

    _simulatedData.removePendingRecord(record.id);

    print('SUCCESS: Record moved. Confirmation ID: $confirmationId');
    return confirmationId;
  }

  // Duplicate check using simulated data: consider duplicate if motherName + childName + dob + gender match
  Future<bool> checkDuplicate(BirthRecord record) async {
    // In real firestore you'd query indexed fields; here we check the in-memory list
    final existing = _simulatedData.getPendingRecordsSync();
    final duplicate = existing.any(
      (r) =>
          r.motherName.toLowerCase().trim() ==
              record.motherName.toLowerCase().trim() &&
          r.childName.toLowerCase().trim() ==
              record.childName.toLowerCase().trim() &&
          r.dob.trim() == record.dob.trim() &&
          r.gender.toLowerCase().trim() == record.gender.toLowerCase().trim(),
    );
    return duplicate;
  }
}

// --- DATA MODEL ---
class BirthRecord {
  final String id;
  final String vhwId;

  // Maternal Health Fields
  final String motherName;
  final int motherAge;
  final int gravida;
  final int parity;
  final bool ancBooked;
  final String? ancFacility;
  final int gestationWeeks;

  // Child & Birth Fields
  final String childName;
  final String gender;
  final double weight;

  // New fields: Date of birth, place, coords
  final String dob; // YYYY-MM-DD
  final String placeOfBirth;
  final double? latitude;
  final double? longitude;

  // Status Fields
  final bool isConfirmed;
  final String? confirmationId;

  BirthRecord({
    required this.id,
    required this.vhwId,
    required this.motherName,
    required this.motherAge,
    required this.gravida,
    required this.parity,
    required this.ancBooked,
    this.ancFacility,
    required this.gestationWeeks,
    required this.childName,
    required this.gender,
    required this.weight,
    this.dob = '',
    this.placeOfBirth = '',
    this.latitude,
    this.longitude,
    this.isConfirmed = false,
    this.confirmationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'vhwId': vhwId,
      // Mother
      'motherName': motherName,
      'motherAge': motherAge,
      'gravida': gravida,
      'parity': parity,
      'ancBooked': ancBooked,
      'ancFacility': ancFacility,
      'gestationWeeks': gestationWeeks,
      // Child
      'childName': childName,
      'gender': gender,
      'weight': weight,
      // New fields
      'dob': dob,
      'placeOfBirth': placeOfBirth,
      'latitude': latitude,
      'longitude': longitude,
      // Status
      'isConfirmed': isConfirmed,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toMapWithConfirmation(String confId) {
    return {
      ...toMap(),
      'confirmationId': confId,
      'isConfirmed': true,
      'confirmedBy': 'VillageHead',
    };
  }
}

// --- MAIN APP STRUCTURE ---
class CommunityBirthApp extends StatefulWidget {
  const CommunityBirthApp({super.key});

  @override
  State<CommunityBirthApp> createState() => _CommunityBirthAppState();
}

class _CommunityBirthAppState extends State<CommunityBirthApp> {
  String? _currentUserId;
  FireStoreService? _firestoreService;

  bool get isVhw => _currentUserId?.startsWith('vhw_') ?? false;
  bool get isVillageHead => _currentUserId?.startsWith('vh_') ?? false;

  @override
  void initState() {
    super.initState();
    _initializeAppAndAuthenticate();
  }

  void _initializeAppAndAuthenticate() async {
    print('App initializing with ID: ${__app_id}');
  }

  void _login(String userId) {
    if (userId.trim().isEmpty) return;

    if (!userId.startsWith('vhw_') && !userId.startsWith('vh_')) {
      _showSnackbar('Invalid ID prefix. Use vhw_ or vh_.');
      return;
    }

    setState(() {
      _currentUserId = userId;
      _firestoreService = FireStoreService(__app_id, userId);
    });
  }

  void _logout() {
    setState(() {
      _currentUserId = null;
      _firestoreService = null;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    if (_currentUserId == null) {
      currentScreen = LoginScreen(onLogin: _login);
    } else if (isVhw) {
      currentScreen = BirthCaptureScreen(
        vhwId: _currentUserId!,
        firestoreService: _firestoreService!,
        onLogout: _logout,
      );
    } else if (isVillageHead) {
      currentScreen = ConfirmationScreen(
        firestoreService: _firestoreService!,
        onLogout: _logout,
      );
    } else {
      currentScreen = const Center(child: Text("Unknown Role"));
    }

    return MaterialApp(
      title: 'Community Birth Reg',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: currentScreen,
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final ValueChanged<String> onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  String _hintText = 'e.g., vhw_sarah or vh_samuel';

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.baby_changing_station,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 20),
              const Text(
                'Community Birth Registration',
                style: kTitleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'Enter Your ID',
                  hintText: _hintText,
                  prefixIcon: const Icon(Icons.badge, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.startsWith('vhw_')) {
                      _hintText = 'Logging in as Village Health Worker';
                    } else if (value.startsWith('vh_')) {
                      _hintText = 'Logging in as Village Head';
                    } else {
                      _hintText = 'Use vhw_ or vh_ prefix';
                    }
                  });
                },
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () =>
                    widget.onLogin(_idController.text.trim().toLowerCase()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Use vhw_sarah or vh_samuel to test roles.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- VHW BIRTH CAPTURE SCREEN ---
class BirthCaptureScreen extends StatefulWidget {
  final String vhwId;
  final FireStoreService firestoreService;
  final VoidCallback onLogout;
  const BirthCaptureScreen({
    super.key,
    required this.vhwId,
    required this.firestoreService,
    required this.onLogout,
  });

  @override
  State<BirthCaptureScreen> createState() => _BirthCaptureScreenState();
}

class _BirthCaptureScreenState extends State<BirthCaptureScreen> {
  final _formKey = GlobalKey<FormState>();

  // Maternal Health Variables
  String _motherName = '';
  int _motherAge = 0;
  int _gravida = 0;
  int _parity = 0;
  bool _ancBooked = false;
  String _ancFacility = '';
  int _gestationWeeks = 0;

  // Child & Birth Variables
  String _childName = '';
  String _gender = 'Male';
  double _weight = 0.0;
  String _dob = ''; // YYYY-MM-DD
  String _placeOfBirth = '';

  double? _latitude;
  double? _longitude;

  bool _isSubmitting = false;

  Future<void> _captureLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showDialog(
          'Location Error',
          'Enable GPS to capture address location.',
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showDialog('Location Error', 'Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showDialog(
          'Location Error',
          'Location permission permanently denied. Please enable from settings.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      _showDialog(
        'Location Captured',
        'Lat: ${_latitude?.toStringAsFixed(6)}, Long: ${_longitude?.toStringAsFixed(6)} stored with record.',
      );
    } catch (e) {
      _showDialog('Location Error', 'Failed to capture location: $e');
      print(e);
    }
  }

  void _submitBirthRecord() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_ancBooked && _ancFacility.trim().isEmpty) {
        _showDialog(
          'Validation Error',
          'ANC Facility Name is required since ANC was booked.',
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      final record = BirthRecord(
        id: 'TEMP_ID',
        vhwId: widget.vhwId,
        motherName: _motherName,
        motherAge: _motherAge,
        gravida: _gravida,
        parity: _parity,
        ancBooked: _ancBooked,
        ancFacility: _ancBooked ? _ancFacility : null,
        gestationWeeks: _gestationWeeks,
        childName: _childName,
        gender: _gender,
        weight: _weight,
        dob: _dob,
        placeOfBirth: _placeOfBirth,
        latitude: _latitude,
        longitude: _longitude,
      );

      try {
        // Duplicate check
        final isDuplicate = await widget.firestoreService.checkDuplicate(
          record,
        );
        if (isDuplicate) {
          _showDialog(
            'Possible Duplicate Detected',
            'A similar record (mother + child + DOB + gender) already exists in pending records. Please verify before submitting.',
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        await widget.firestoreService.submitNewBirth(record);
        _showDialog(
          'Success!',
          'Birth record submitted successfully. Awaiting Village Head confirmation.',
        );
        _formKey.currentState!.reset();

        setState(() {
          _gender = 'Male';
          _weight = 0.0;
          _motherAge = 0;
          _gravida = 0;
          _parity = 0;
          _ancBooked = false;
          _ancFacility = '';
          _gestationWeeks = 0;
          _dob = '';
          _placeOfBirth = '';
          _latitude = null;
          _longitude = null;
        });
      } catch (e) {
        _showDialog('Error', 'Failed to submit record. Please try again.');
        print(e);
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Birth Registration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Logout (${widget.vhwId})',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Logged in as VHW: ${widget.vhwId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const Divider(),

              _buildSectionTitle('Mother Demographics & History'),

              _buildTextFormField(
                label: 'Mother\'s Full Name',
                onSaved: (value) => _motherName = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Name is required' : null,
              ),
              _buildNumericFormField(
                label: 'Age',
                onSaved: (value) => _motherAge = value!,
                validator: (value) => value! < 12 || value > 60
                    ? 'Enter valid age (12-60)'
                    : null,
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildNumericFormField(
                      label: 'Gravida (Total Pregnancies)',
                      onSaved: (value) => _gravida = value!,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildNumericFormField(
                      label: 'Parity (Previous Births)',
                      onSaved: (value) => _parity = value!,
                    ),
                  ),
                ],
              ),

              _buildSectionTitle('Antenatal Care (ANC) Details'),

              SwitchListTile(
                title: const Text('ANC Booking Done?'),
                value: _ancBooked,
                onChanged: (bool value) {
                  setState(() {
                    _ancBooked = value;
                  });
                },
                activeColor: primaryColor,
                contentPadding: EdgeInsets.zero,
              ),

              if (_ancBooked)
                _buildTextFormField(
                  label: 'ANC Facility Name (Required if booked)',
                  onSaved: (value) => _ancFacility = value!,
                ),

              _buildNumericFormField(
                label: 'Gestation Period at Birth (Weeks)',
                onSaved: (value) => _gestationWeeks = value!,
                validator: (value) => value! < 20 || value > 45
                    ? 'Enter valid weeks (20-45)'
                    : null,
              ),

              const SizedBox(height: 30),
              _buildSectionTitle('Child & Birth Details'),

              _buildTextFormField(
                label: 'Child\'s Name (if named)',
                onSaved: (value) => _childName = value!,
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildGenderDropdown()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildWeightField()),
                ],
              ),

              _buildTextFormField(
                label: 'Date of Birth (YYYY-MM-DD)',
                keyboardType: TextInputType.datetime,
                onSaved: (value) => _dob = value ?? '',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Date of birth required';
                  }
                  // Basic format check YYYY-MM-DD
                  final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!regex.hasMatch(value.trim())) {
                    return 'Use YYYY-MM-DD';
                  }
                  return null;
                },
              ),
              _buildTextFormField(
                label: 'Place of Birth (Home/Facility)',
                onSaved: (value) => _placeOfBirth = value ?? '',
                validator: (value) =>
                    value!.isEmpty ? 'Place of birth required' : null,
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _captureLocation,
                      icon: const Icon(Icons.location_on),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      label: const Text('Capture Birth Location'),
                    ),
                  ),
                ],
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Captured coords: ${_latitude?.toStringAsFixed(6)}, ${_longitude?.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitBirthRecord,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit to Village Head',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    ValueChanged<String?>? onSaved,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  Widget _buildNumericFormField({
    required String label,
    ValueChanged<int?>? onSaved,
    String? Function(int?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onSaved: (value) {
          onSaved?.call(int.tryParse(value ?? '0') ?? 0);
        },
        validator: (value) {
          final int? parsedValue = int.tryParse(value ?? '');
          if (parsedValue == null || parsedValue < 0) {
            return 'Enter a valid positive number';
          }
          if (validator != null) {
            return validator(parsedValue);
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Child\'s Gender',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: [
        'Male',
        'Female',
        'Intersex',
      ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (newValue) {
        setState(() {
          _gender = newValue!;
        });
      },
      onSaved: (value) => _gender = value!,
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      initialValue: _weight > 0 ? _weight.toString() : '',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Weight (kg)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onSaved: (value) => _weight = double.tryParse(value ?? '0') ?? 0.0,
      validator: (value) {
        if (double.tryParse(value ?? '') == null ||
            (double.tryParse(value ?? '') ?? 0) <= 0.5) {
          return 'Enter valid weight (>0.5kg)';
        }
        return null;
      },
    );
  }
}

// --- VILLAGE HEAD CONFIRMATION SCREEN ---
class ConfirmationScreen extends StatefulWidget {
  final FireStoreService firestoreService;
  final VoidCallback onLogout;
  const ConfirmationScreen({
    super.key,
    required this.firestoreService,
    required this.onLogout,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  String? _confirmationId;
  String _searchQuery = '';

  void _confirmRecord(BirthRecord record) async {
    final bool? shouldConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Birth Record'),
        content: Text(
          'Are you sure you want to confirm the birth for mother ${record.motherName} (Age: ${record.motherAge})? This action is final.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldConfirm == true) {
      setState(() {
        _confirmationId = 'processing';
      });
      try {
        final newId = await widget.firestoreService.confirmBirth(record);
        setState(() {
          _confirmationId = newId;
        });
      } catch (e) {
        _showSnackbar('Confirmation failed.');
        setState(() {
          _confirmationId = null;
        });
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearConfirmation() {
    setState(() {
      _confirmationId = null;
    });
  }

  bool _matchesSearch(BirthRecord r) {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return true;
    return r.motherName.toLowerCase().contains(q) ||
        r.childName.toLowerCase().contains(q) ||
        r.vhwId.toLowerCase().contains(q) ||
        r.placeOfBirth.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birth Confirmation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Logout (Village Head)',
          ),
        ],
      ),
      body: _confirmationId != null && _confirmationId != 'processing'
          ? ConfirmationOutput(
              confirmationId: _confirmationId!,
              onComplete: _clearConfirmation,
            )
          : StreamBuilder<List<BirthRecord>>(
              // This stream now ensures the initial list is returned immediately upon connection.
              stream: widget.firestoreService.streamPendingRecords(),
              builder: (context, snapshot) {
                if (_confirmationId == 'processing' ||
                    (!snapshot.hasData &&
                        snapshot.connectionState == ConnectionState.waiting)) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        SizedBox(height: 10),
                        Text('Loading pending records...'),
                      ],
                    ),
                  );
                }

                // If we reached this point, we have data (or an empty list if successful)
                final records = snapshot.data ?? [];

                final filtered = records.where(_matchesSearch).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by Mother, Child, VHW ID, or Place',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'No pending birth records requiring confirmation.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(10),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final record = filtered[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.pending_actions,
                                      color: secondaryColor,
                                    ),
                                    title: Text(
                                      'Mother: ${record.motherName} (Age: ${record.motherAge})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ANC: ${record.ancBooked ? 'Booked (${record.ancFacility})' : 'Not Booked'}\nDOB: ${record.dob} | Gravida/Parity: ${record.gravida}/${record.parity} | Child: ${record.weight}kg\nPlace: ${record.placeOfBirth}',
                                    ),
                                    isThreeLine: true,
                                    trailing: ElevatedButton(
                                      onPressed: () => _confirmRecord(record),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                      ),
                                      child: const Text(
                                        'Confirm',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// --- CONFIRMATION OUTPUT SCREEN (Confirmation Message + QR Code) ---
class ConfirmationOutput extends StatelessWidget {
  final String confirmationId;
  final VoidCallback onComplete;
  const ConfirmationOutput({
    super.key,
    required this.confirmationId,
    required this.onComplete,
  });

  String get _qrData =>
      'BirthRecordID:$confirmationId|Facility:NearestClinic|Date:${DateTime.now().toIso8601String().substring(0, 10)}';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Birth Confirmed!',
              style: kTitleStyle.copyWith(color: primaryColor),
            ),
            const SizedBox(height: 10),
            const Text(
              'This confirmation validates the birth record and enables the issuance of a birth record at the nearest health facility.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 30),

            Text(
              'Confirmation ID:',
              style: kLabelStyle.copyWith(color: Colors.grey.shade600),
            ),
            Text(
              confirmationId,
              style: kTitleStyle.copyWith(fontSize: 28, color: secondaryColor),
            ),

            const SizedBox(height: 40),

            // --- QR Code Placeholder (Simulating qr_flutter output) ---
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: secondaryColor, width: 4),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2, color: Colors.white, size: 60),
                    const SizedBox(height: 5),
                    Text(
                      'QR CODE DATA\n(Encoded for Clinic Scanner)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _qrData,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 179, 178, 93),
                        fontSize: 8,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Complete & View List',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- APP ENTRY POINT ---
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityBirthApp();
  }
}

void main() {
  runApp(const MainApp());
}
