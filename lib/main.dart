import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SpeedWashApp());
}

class SpeedWashApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeedWash Premium',
      theme: ThemeData(
        primaryColor: Color(0xFFD92323),
        scaffoldBackgroundColor: Color(0xFFF2F4F8),
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// =============================================
// SPLASH SCREEN
// =============================================
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(Duration(seconds: 2));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD92323),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_car_wash, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'SpeedWash',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            SizedBox(height: 50),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// =============================================
// HOME SCREEN
// =============================================
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  PageController _pageController = PageController();
  bool _isLoggedIn = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _setupNotifications();
  }

  Future<void> _checkAuthState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _isLoggedIn = true;
        _currentUser = doc.data() as Map<String, dynamic>?;
      });
    }
  }

  Future<void> _setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    String? token = await messaging.getToken();
    print("FCM Token: $token");
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
  }

  void _showNotification(RemoteMessage message) {
    Vibration.vibrate(duration: 200);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Update'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: [
          _buildHomeView(),
          _buildBookingView('bike'),
          _buildBookingView('car'),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFD92323),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.two_wheeler),
            label: 'Bike',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Car',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF25D366),
        onPressed: () async {
          await launch('https://wa.me/918927646785');
        },
        child: Icon(Icons.whatsapp, color: Colors.white),
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SpeedWash',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                GestureDetector(
                  onTap: _openLocationPicker,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _isLoggedIn 
                            ? 'Hello ${_currentUser?['name']?.split(' ')[0] ?? 'User'}'
                            : 'Hello Guest',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Color(0xFFD92323)),
                          SizedBox(width: 4),
                          Text(
                            'Locate Me',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD92323),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Refer Banner
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1e1e1e), Color(0xFF3a3a3a)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFFC107)),
              ),
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refer & Get ₹100',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFC107),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Friend gets 50% OFF their first wash!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _handleReferral,
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 16),
                        SizedBox(width: 5),
                        Text('Share'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hero Slider
          Container(
            height: 200,
            child: PageView(
              children: [
                _buildSlideCard(
                  '50% OFF\nFirst Wash',
                  'Premium Doorstep Service',
                  Color(0xFFD92323),
                ),
                _buildSlideCard(
                  'Bike Wash\n₹99 Only',
                  'With Monthly Plan',
                  Colors.black,
                ),
              ],
            ),
          ),

          // Services
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildServiceCard(
                        Icons.two_wheeler,
                        'Bike Wash',
                        'Starts ₹99 (Monthly)',
                        'SAVE ₹197',
                        Color(0xFFD92323),
                        () => _pageController.jumpToPage(1),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _buildServiceCard(
                        Icons.directions_car,
                        'Car Wash',
                        'Starts ₹299 (Monthly)',
                        'SAVE UP TO ₹897',
                        Colors.black,
                        () => _pageController.jumpToPage(2),
                        isHighlighted: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Why Choose Us
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why Choose Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 15),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildFeatureItem(Icons.home, 'Doorstep'),
                    _buildFeatureItem(Icons.security, 'Pro Staff'),
                    _buildFeatureItem(Icons.water_drop, 'Less Water'),
                    _buildFeatureItem(Icons.battery_full, 'Own Power'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideCard(String title, String subtitle, Color color) {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFFD92323),
            ),
            onPressed: () => _pageController.jumpToPage(2),
            child: Text('Book Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    IconData icon,
    String title,
    String subtitle,
    String badge,
    Color color,
    VoidCallback onTap, {
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isHighlighted
              ? Border.all(color: Color(0xFFD92323))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
            ),
          ],
        ),
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFFF4F6F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Color(0xFFD92323)),
            ),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 15),
            OutlinedButton(
              onPressed: onTap,
              child: Text('Book ${title.split(' ')[0]} Wash'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFD92323)),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingView(String type) {
    return BookingWizard(type: type);
  }

  void _openLocationPicker() {
    // Implement location picker
  }

  void _handleReferral() {
    if (!_isLoggedIn) {
      showDialog(
        context: context,
        builder: (context) => LoginModal(),
      );
      return;
    }
    
    Share.share(
      'Use my code ${_currentUser?['referralCode'] ?? 'SPEEDWASH'} to get 50% OFF your first car wash!',
    );
  }
}

// =============================================
// BOOKING WIZARD
// =============================================
class BookingWizard extends StatefulWidget {
  final String type;

  const BookingWizard({Key? key, required this.type}) : super(key: key);

  @override
  _BookingWizardState createState() => _BookingWizardState();
}

class _BookingWizardState extends State<BookingWizard> {
  int _currentStep = 1;
  String? _selectedCarType = 'hatch';
  String? _selectedService = 'exterior';
  String? _selectedPlan = 'monthly';
  String? _selectedDate = 'today';
  String? _selectedTime;
  TextEditingController _modelController = TextEditingController();
  TextEditingController _numberController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  bool _provideWater = false;
  double _tipAmount = 0;

  final Map<String, Map<String, Map<String, Map<String, int>>>> _carPrices = {
    'hatch': {
      'exterior': {'s': 299, 'm': 899},
      'full': {'s': 399, 'm': 1299},
    },
    'sedan': {
      'exterior': {'s': 399, 'm': 1199},
      'full': {'s': 499, 'm': 1499},
    },
    'csuv': {
      'exterior': {'s': 499, 'm': 1399},
      'full': {'s': 699, 'm': 2299},
    },
    'suv': {
      'exterior': {'s': 599, 'm': 1499},
      'full': {'s': 799, 'm': 2499},
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.type == 'car' ? 'Car Wash Booking' : 'Bike Wash Booking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepNode(1, 'Plan'),
                _buildStepNode(2, 'Details'),
                _buildStepNode(3, 'Checkout'),
              ],
            ),
          ),

          Expanded(
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: PageController(initialPage: _currentStep - 1),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),

          // Sticky Footer
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convenience Fee: FREE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _calculateTotal().toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD92323),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD92323),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    _currentStep == 3 ? 'Pay & Book' : 'Next Step',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(int step, String label) {
    bool isActive = step == _currentStep;
    bool isCompleted = step < _currentStep;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? Color(0xFF2E7D32)
                : isActive
                    ? Color(0xFFD92323)
                    : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Color(0xFFD92323) : Colors.grey[300]!,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Color(0xFFD92323).withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.grey,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Color(0xFFD92323) : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    if (widget.type == 'bike') {
      return _buildBikeStep1();
    } else {
      return _buildCarStep1();
    }
  }

  Widget _buildBikeStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 15),
          _buildPlanCard(
            'Monthly Subscription',
            '4 Washes • ₹99/wash',
            '₹399',
            isActive: _selectedPlan == 'monthly',
            isMostPopular: true,
            onTap: () => setState(() => _selectedPlan = 'monthly'),
          ),
          SizedBox(height: 10),
          _buildPlanCard(
            'Single Wash',
            'One time deep clean',
            '₹149',
            isActive: _selectedPlan == 'single',
            onTap: () => setState(() => _selectedPlan = 'single'),
          ),
        ],
      ),
    );
  }

  Widget _buildCarStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Select Car Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildCarTypeCard('HATCHBACK', 'hatch'),
              _buildCarTypeCard('SEDAN', 'sedan'),
              _buildCarTypeCard('COMPACT SUV', 'csuv'),
              _buildCarTypeCard('SUV / MPV', 'suv'),
            ],
          ),
          SizedBox(height: 20),
          Text(
            '2. Select Service & Plan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildServiceTab('Exterior Only', 'exterior'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildServiceTab('Ext + Interior', 'full'),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildPlanCard(
            'Monthly (4 Washes)',
            'Effectively ₹${(_carPrices[_selectedCarType]?[_selectedService]?['m'] ?? 0) ~/ 4}/wash',
            '₹${_carPrices[_selectedCarType]?[_selectedService]?['m'] ?? 0}',
            isActive: _selectedPlan == 'monthly',
            isMostPopular: true,
            onTap: () => setState(() => _selectedPlan = 'monthly'),
          ),
          SizedBox(height: 10),
          _buildPlanCard(
            'One Time Wash',
            'Deep Clean',
            '₹${_carPrices[_selectedCarType]?[_selectedService]?['s'] ?? 0}',
            isActive: _selectedPlan == 'single',
            onTap: () => setState(() => _selectedPlan = 'single'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    String title,
    String subtitle,
    String price, {
    bool isActive = false,
    bool isMostPopular = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? (isMostPopular ? Color(0xFFD92323) : Color(0xFFD92323))
                : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isMostPopular
              ? [
                  BoxShadow(
                    color: Color(0xFFD92323).withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ]
              : [],
        ),
        padding: EdgeInsets.all(15),
        child: Stack(
          children: [
            if (isMostPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFC107),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD92323),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarTypeCard(String label, String value) {
    bool isActive = _selectedCarType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCarType = value),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Color(0xFFD92323) : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isActive ? Color(0xFFD92323) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTab(String label, String value) {
    bool isActive = _selectedService == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedService = value),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.black : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle & Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 15),
          _buildInputField(
            Icons.directions_car,
            'Vehicle Model Name',
            _modelController,
          ),
          SizedBox(height: 10),
          _buildInputField(
            Icons.tag,
            'Vehicle Number',
            _numberController,
          ),
          SizedBox(height: 10),
          _buildLocationField(),
          SizedBox(height: 20),
          Text(
            'Select Date & Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildDateTab('Today', 'today'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildDateTab('Tomorrow', 'tomorrow'),
              ),
            ],
          ),
          SizedBox(height: 15),
          _buildTimeSlots(),
          SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: _provideWater,
                onChanged: (value) => setState(() => _provideWater = value!),
                activeColor: Color(0xFFD92323),
              ),
              Text('Can you provide 1-2 buckets of water?'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    IconData icon,
    String hint,
    TextEditingController controller,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildLocationField() {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.location_on, color: Color(0xFFD92323)),
        hintText: 'Click GPS Icon ->',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(Icons.gps_fixed, color: Color(0xFFD92323)),
          onPressed: _getCurrentLocation,
        ),
      ),
      onTap: _openMapPicker,
    );
  }

  Widget _buildDateTab(String label, String value) {
    bool isActive = _selectedDate == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDate = value),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.black : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    List<String> morningSlots = ['8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM'];
    List<String> afternoonSlots = ['12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MORNING SLOTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: morningSlots
              .map((slot) => _buildTimeChip(slot))
              .toList(),
        ),
        SizedBox(height: 20),
        Text(
          'AFTERNOON SLOTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: afternoonSlots
              .map((slot) => _buildTimeChip(slot))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTimeChip(String time) {
    bool isActive = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.black : Colors.grey[300]!,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    double basePrice = widget.type == 'bike'
        ? (_selectedPlan == 'monthly' ? 399 : 149)
        : (_selectedPlan == 'monthly'
            ? (_carPrices[_selectedCarType]?[_selectedService]?['m'] ?? 0).toDouble()
            : (_carPrices[_selectedCarType]?[_selectedService]?['s'] ?? 0).toDouble());
    
    double total = basePrice + _tipAmount;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Summary Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _selectedPlan == 'monthly'
                            ? 'Monthly Subscription'
                            : 'One Time Wash',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildBillRow('Item Total', '₹${basePrice.toStringAsFixed(0)}'),
                      _buildBillRow('Convenience Fee', 'FREE'),
                      SizedBox(height: 20),
                      Text(
                        'Tip your washer (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTipButton(10),
                          SizedBox(width: 10),
                          _buildTipButton(30),
                          SizedBox(width: 10),
                          _buildTipButton(50),
                        ],
                      ),
                      SizedBox(height: 20),
                      Divider(),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To Pay',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Incl. of all taxes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD92323),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipButton(double amount) {
    bool isActive = _tipAmount == amount;
    return GestureDetector(
      onTap: () => setState(() => _tipAmount = isActive ? 0 : amount),
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.black : Colors.grey[300]!,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _initiatePayment();
    }
  }

  void _getCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        // Use the position
      } catch (e) {
        print("Error getting location: $e");
      }
    }
  }

  void _openMapPicker() {
    // Implement map picker
  }

  double _calculateTotal() {
    double basePrice = widget.type == 'bike'
        ? (_selectedPlan == 'monthly' ? 399 : 149)
        : (_selectedPlan == 'monthly'
            ? (_carPrices[_selectedCarType]?[_selectedService]?['m'] ?? 0).toDouble()
            : (_carPrices[_selectedCarType]?[_selectedService]?['s'] ?? 0).toDouble());
    
    return basePrice + _tipAmount;
  }

  void _initiatePayment() {
    Razorpay razorpay = Razorpay();
    
    var options = {
      'key': 'YOUR_RAZORPAY_KEY',
      'amount': (_calculateTotal() * 100).toInt(),
      'name': 'SpeedWash Premium',
      'description': '${widget.type.toUpperCase()} Wash Booking',
      'prefill': {
        'contact': '9999999999',
        'email': 'user@example.com'
      },
      'theme': {'color': '#D92323'}
    };

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    try {
      razorpay.open(options);
    } catch (e) {
      print(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _createBooking();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  void _createBooking() async {
    // Implement booking creation in Firebase
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Confirmed!'),
        content: Text('Your wash has been scheduled successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

// =============================================
// ACCOUNT SCREEN
// =============================================
class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _user;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      
      QuerySnapshot orders = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: _user!.uid)
          .get();

      setState(() {
        _userData = doc.data() as Map<String, dynamic>?;
        _orders = orders.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _user == null
          ? _buildGuestView()
          : _buildUserView(),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 50, color: Colors.grey),
          ),
          SizedBox(height: 20),
          Text(
            'Guest User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD92323),
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => LoginModal(),
              );
            },
            child: Text('Login Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // User Header
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.person, size: 30, color: Colors.grey),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData?['name'] ?? 'User',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            _userData?['phone'] ?? '',
                            style: TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: 5),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'VERIFIED MEMBER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1565C0),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        'Vehicle',
                        _userData?['vehicle'] ?? 'Not set',
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: _buildStatBox(
                        'Wallet',
                        '₹${_userData?['walletBalance'] ?? 0}',
                        isWallet: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Referral Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refer & Earn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 15),
                _buildReferralCard(),
              ],
            ),
          ),

          // Active Orders
          if (_orders.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 15),
                  ..._orders
                      .where((order) => !['Completed', 'Cancelled']
                          .contains(order['status']))
                      .map(_buildOrderCard)
                      .toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {bool isWallet = false}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWallet ? Color(0xFFFFF8E1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWallet ? Color(0xFFFFE082) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isWallet ? Color(0xFFFF6F00) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.card_giftcard, color: Color(0xFFFF9800)),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Rewards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {},
                child: Text('View My Referrals'),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.dashed),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Code',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _userData?['referralCode'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD92323),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: _copyReferralCode,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD92323),
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed: _shareReferral,
            child: Text('Invite Friends Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order['id']?.substring(0, 5).toUpperCase() ?? ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 12),
                    SizedBox(width: 5),
                    Text(
                      order['status'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            order['details'] ?? '',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 10),
          Text(
            order['time'] ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          if (['Booked', 'Confirmed'].contains(order['status'])) ...[
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Reschedule Wash?',
                  style: TextStyle(
                    color: Color(0xFFD92323),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Confirmed':
        return Color(0xFFFEF9C3);
      case 'On the Way':
        return Color(0xFFF3E8FF);
      case 'Reached Location':
        return Color(0xFFFEE2E2);
      case 'Completed':
        return Color(0xFFDCFCE7);
      default:
        return Color(0xFFE0F2FE);
    }
  }

  void _copyReferralCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Referral code copied!')),
    );
  }

  void _shareReferral() {
    Share.share(
      'Use my code ${_userData?['referralCode']} to get 50% OFF your first car wash!',
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }
}

// =============================================
// LOGIN MODAL
// =============================================
class LoginModal extends StatefulWidget {
  @override
  _LoginModalState createState() => _LoginModalState();
}

class _LoginModalState extends State<LoginModal> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  bool _isOtpSent = false;
  String _verificationId = '';
  List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (!_isOtpSent) _buildLoginForm() else _buildOtpForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildInputField(
          Icons.phone,
          'Mobile Number',
          _phoneController,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 15),
        _buildInputField(
          Icons.person,
          'Name',
          _nameController,
        ),
        SizedBox(height: 15),
        _buildInputField(
          Icons.email,
          'Email ID',
          _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 15),
        _buildInputField(
          Icons.directions_car,
          'Vehicle Number',
          _vehicleController,
        ),
        SizedBox(height: 15),
        _buildInputField(
          Icons.tag,
          'Referral Code (Optional)',
          _referralController,
        ),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFD92323),
            minimumSize: Size(double.infinity, 50),
          ),
          onPressed: _sendOtp,
          child: Text('Get OTP'),
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    return Column(
      children: [
        Text(
          'Enter the 6-digit code sent to you',
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            6,
            (index) => Container(
              width: 45,
              height: 45,
              margin: EdgeInsets.symmetric(horizontal: 5),
              child: TextField(
                controller: _otpControllers[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFD92323),
            minimumSize: Size(double.infinity, 50),
          ),
          onPressed: _verifyOtp,
          child: Text('Verify & Login'),
        ),
      ],
    );
  }

  Widget _buildInputField(
    IconData icon,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
    );
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill Name and Phone')),
      );
      return;
    }

    String phoneNumber = '+91${_phoneController.text}';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isOtpSent = true;
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    String otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter full OTP')),
      );
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Save user data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text,
        'phone': userCredential.user!.phoneNumber,
        'email': _emailController.text,
        'vehicle': _vehicleController.text,
        'referralCode': _generateReferralCode(),
        'walletBalance': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  String _generateReferralCode() {
    String name = _nameController.text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    String phone = _phoneController.text;
    String prefix = name.length >= 4 ? name.substring(0, 4).toUpperCase() : 'SPEED';
    String suffix = phone.length >= 2 ? phone.substring(phone.length - 2) : '00';
    return '$prefix$suffix';
  }
}