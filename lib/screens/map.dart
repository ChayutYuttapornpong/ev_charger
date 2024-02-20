import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../main.dart';




class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
   final Completer<GoogleMapController> _controller = Completer();
   final FirebaseAuth _auth = FirebaseAuth.instance;
// รายการ feedback ทั้งหมด
  double zoomVal = 5.0;
  List<DocumentSnapshot> EV = [];
  Set<Polyline> _polylines = {};
  double _userRating = 0.0;
String _userFeedback = '';

  // ติดตาม Marker ที่ถูกแตะ
  @override
  void initState() {
    super.initState();
    fetchEV();
    _requestLocationPermission();
  }
 Future<void> fetchEV() async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('locations').get();

  // Calculate and set distance for each EV
  for (var doc in snapshot.docs) {
    double lat = doc['latitude'] as double;
    double long = doc['longitude'] as double;
    double distance = await _getDistance(lat, long);

    // Update the document in Firestore using DocumentReference
    FirebaseFirestore.instance.collection('locations').doc(doc.id).update({
      'distance': distance,
      'distanceText': (distance / 1000.0).toStringAsFixed(2) + ' km away',
    });
  }

  // Retrieve the updated data after updating Firestore
  QuerySnapshot updatedSnapshot = await FirebaseFirestore.instance.collection('locations').get();

  // Update EV list
  setState(() {
    EV = updatedSnapshot.docs;
  });
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Stack(
        children: <Widget>[
          _buildGoogleMap(context),
          if (EV.isNotEmpty) _buildContainer(), // เพิ่มเงื่อนไขตรวจสอบ EV
        ],
            ),
      ),
    );
  }

Future<double> _getDistance(double destinationLat, double destinationLong) async {
  try {
    Position currentPosition = await Geolocator.getCurrentPosition();
    double distanceInMeters = await Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      destinationLat,
      destinationLong,
    );
    return distanceInMeters;
  } catch (e) {
    print('Error getting distance: $e');
    return 0.0;
  }
}
Future<void> _requestLocationPermission() async {
  var status = await Permission.location.request();

  if (status == PermissionStatus.granted) {
    // ทำตามขั้นตอนที่ต้องการทำหลังจากได้รับอนุญาต
    print('Location permission granted');
  } else {
    // แจ้งเตือนหรือทำตามตามที่คุณต้องการเมื่อไม่ได้รับอนุญาต
    print('Location permission denied');
  }
}
Future<void> _gotoLocation(double lat, double long) async {
  final GoogleMapController controller = await _controller.future;

  // ดึงตำแหน่งปัจจุบัน
  Position currentPosition = await Geolocator.getCurrentPosition();
  double currentLat = currentPosition.latitude;
  double currentLong = currentPosition.longitude;

  // เรียกใช้ FlutterPolylinePoints
  PolylinePoints polylinePoints = PolylinePoints();

  // กำหนดตำแหน่งเริ่มและสิ้นสุด
  PointLatLng startLatLng = PointLatLng(currentLat, currentLong);
  PointLatLng endLatLng = PointLatLng(lat, long);

 // ดึงเส้นทาง
  PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
    'AIzaSyDfep5HgNL_RXKAalzR0QAWObeikpqAc9c', // แทน YOUR_GOOGLE_MAPS_API_KEY ด้วย API Key ของคุณ
    startLatLng,
    endLatLng,
    travelMode: TravelMode.driving,
  );

  // ตรวจสอบว่ามีข้อมูลเส้นทาง
  if (result.status == 'OK') {
    // แปลง List<PointLatLng> เป็น List<LatLng>
    List<LatLng> polylineCoordinates = result.points
        .map((PointLatLng point) => LatLng(point.latitude, point.longitude))
        .toList();

    // สร้าง Polyline object
    Polyline polyline = Polyline(
      polylineId: const PolylineId('route1'),
      color: Colors.blue,
      points: polylineCoordinates,
      width: 4,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    // อัพเดท Set ของ Polylines
    setState(() {
      _polylines.add(polyline);
    });

   // ขยับแผนที่ไปที่ตำแหน่งปลายทาง
  LatLngBounds bounds = LatLngBounds(
    southwest: LatLng(min(currentLat, lat), min(currentLong, long)),
    northeast: LatLng(max(currentLat, lat), max(currentLong, long)),
  );


  CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50.0);

  controller.animateCamera(cameraUpdate);
  }
}

 Widget _buildContainer() {
    // เรียงลำดับ EV ตามระยะห่างก่อนที่จะสร้าง container
    EV.sort((a, b) {
      double distanceA = a['distance'] as double;
      double distanceB = b['distance'] as double;
      return distanceA.compareTo(distanceB);
    });

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20.0),
        height: 150.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: EV.length,
          itemBuilder: (context, index) {
            try {
              String image = EV[index]['images'] as String;
              double lat = EV[index]['latitude'] as double;
              double long = EV[index]['longitude'] as double;
              String EVName = EV[index]['name'] as String;

              return _boxes(image, lat, long, EVName, EV[index]['distanceText'] as String);
            } catch (e) {
              print('Error building container for document ${EV[index].id}: $e');
              return Container(); // หรือแทนด้วยวิดเจ็ตที่ใช้เป็นตัวยึดตำแหน่ง
            }
          },
        ),
      ),
    );
  }
   Widget _boxes(String _image, double lat, double long, String EVName, String distanceText) {
     print('Image: $_image, Lat: $lat, Long: $long, EVName: $EVName, Distance: $distanceText');
     return GestureDetector(
       onTap: () {
         // นำออกตัวระบบนำทาง
         //_gotoLocation(lat, long);
         _moveCameraToMarker(lat, long);
       },
       child: Container(
         padding: const EdgeInsets.all(10),
         child: FittedBox(
           child: Material(
             color: Colors.white,
             elevation: 14.0,
             borderRadius: BorderRadius.circular(24.0),
             shadowColor: const Color(0x802196F3),
             child: Row(
               children: <Widget>[
                 Container(
                   width: 120, // ปรับขนาดตามต้องการ
                   height: 150, // ปรับขนาดตามต้องการ
                   child: ClipRRect(
                     borderRadius: new BorderRadius.circular(24.0),
                     child: Image(
                       fit: BoxFit.fill,
                       image: NetworkImage(_image),
                     ),
                   ),
                 ),
                 SizedBox(width: 10), // เพิ่มระยะห่างระหว่างรูปภาพและข้อความ
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: <Widget>[
                     Container(
                       width: 250, // ปรับขนาดตามต้องการ
                       child: Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: myDetailsContainer1(EVName),
                       ),
                     ),
                     myDetailsContainer2(distanceText),
                   ],
                 ),
               ],
             ),
           ),
         ),
       ),
     );
   }



   Widget myDetailsContainer1(String EVName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
              child: Text(EVName,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold),
          )),
        ),
      ],
    );
  }

   Widget myDetailsContainer2(String distanceText) {
     return Column(
       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
       children: <Widget>[
         Padding(
           padding: const EdgeInsets.only(left: 100.0),
           child: Container(
               child: Text(distanceText,
                 style: const TextStyle(
                     color: buttoncolors,
                     fontSize: 20.0,
                     fontWeight: FontWeight.bold),
               )),
         ),
       ],
     );
   }

void _moveCameraToMarker(double lat, double long) async {
  final GoogleMapController controller = await _controller.future;

  // ขยับแผนที่ไปที่ตำแหน่งปลายทาง
  CameraPosition destinationPosition = CameraPosition(
    target: LatLng(lat, long),
    zoom: 15.0,
  );

  controller.animateCamera(CameraUpdate.newCameraPosition(destinationPosition));
}
  Widget _buildGoogleMap(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition:  const CameraPosition(target: LatLng(13.755437519298216, 100.50534958162314), zoom: 12),
          myLocationEnabled: true,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          markers: 
           _createMarkers(),
           polylines: _polylines,
          
        ),
      ),
    );
  }

  Set<Marker> _createMarkers() {
  Set<Marker> markers = Set<Marker>();

  for (int i = 0; i < EV.length; i++) {
    try {
      double lat = EV[i]['latitude'] as double;
      double long = EV[i]['longitude'] as double;
      String name = EV[i]['name'] as String;

      print('Marker: Lat=$lat, Long=$long, Name=$name');

      markers.add(
        Marker(
          markerId: MarkerId(EV[i].id),
          position: LatLng(lat, long),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          onTap: () {
              // ตั้งค่า Marker ที่ถูกเลือกเมื่อแตะ
              setState(() {
              });

              // แสดง Bottom Sheet พร้อมรายละเอียด
              _showDetailsBottomSheet(EV[i]);
            },
        ),
        
      );
    } catch (e) {
      print('Error creating marker for document ${EV[i].id}: $e');
    }
  }

  return markers;
}
void _showDetailsBottomSheet(DocumentSnapshot evData) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9, // กำหนดความสูงให้เป็น 90%
            padding: const EdgeInsets.all(10),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildDetailsTab(evData),
                        _buildFeedbackTab(evData),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Details'),
                      Tab(text: 'Feedback'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildDetailsTab(DocumentSnapshot evData) {
  return ListView(
    shrinkWrap: true,
    padding: const EdgeInsets.all(16),
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: 20,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    evData['logo'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(evData['images']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evData['name'] as String,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            evData['distanceText'] as String,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.location_pin, color: buttoncolors),
            title: Text(
              evData['address'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.timelapse_rounded, color: buttoncolors),
            title: Text(
              'เวลา:' + evData['time'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.electric_car_rounded, color: buttoncolors),
            title: Text(
              'Type: ' + evData['Type'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.stars, color: buttoncolors),
            title: Row(
              children: [
                const Text('Rating: '),
                RatingBar(
                  initialRating: _userRating,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  ratingWidget: RatingWidget(
                    full: Icon(Icons.star, color: Colors.amber),
                    half: Icon(Icons.star_half, color: Colors.amber),
                    empty: Icon(Icons.star_border, color: Colors.amber),
                  ),
                  itemSize: 30,
                  onRatingUpdate: (rating) {
                    setState(() {
                      _userRating = rating;
                    });
                  },
                ),
              ],
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: 'Review',
              hintText: 'Provide your feedback here...',
            ),
            onChanged: (value) {
              setState(() {
                _userFeedback = value;
              });
            },
          ),
          ElevatedButton(
            onPressed: () async {
              // ดึงข้อมูลผู้ใช้ที่ล็อกอิน
              User? user = _auth.currentUser;
              // บันทึกคะแนนและ feedback ลง Firestore
              if (user != null) {
                // บันทึกคะแนนและ feedback แยกตามบัญชีผู้ใช้ที่ล็อกอิน
                await FirebaseFirestore.instance.collection('ratings').add({
                  'username': user.displayName, // เพิ่มข้อมูล userId
                  'name': evData['name'],
                  'rating': _userRating,
                  'feedback': _userFeedback,
                });
                // รีเซ็ตค่าคะแนนและ feedback เมื่อ BottomSheet หายไป
                setState(() {
                  _userRating = 0.0;
                  _userFeedback = '';
                });
                // ปิด Bottom Sheet
                Navigator.pop(context);
              }
            },
            child: Text('Submit'),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: buttoncolors),
              onPressed: () {
                // นำทางไปยังตำแหน่ง Marker ที่เลือก
                _gotoLocation(
                  evData['latitude'] as double,
                  evData['longitude'] as double,
                );
                Navigator.pop(context); // ปิด Bottom Sheet
              },
              child: const IntrinsicWidth(
                child: IntrinsicHeight(
                  child: ListTile(
                    leading: Icon(Icons.location_pin, color: Colors.white),
                    title: Text(
                      'Navigation',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildFeedbackTab(DocumentSnapshot evData) {
  // ดึง feedback ทั้งหมดของ EV นี้จาก Firestore
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('ratings')
        .where('name', isEqualTo: evData['name'])
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else {
        List<double> ratings = [];
        List<String> feedbacks = [];

        // ดึงข้อมูลคะแนนและ feedback จาก Firestore
        for (var doc in snapshot.data!.docs) {
          double rating = doc['rating'] as double;
          String feedback = doc['feedback'] as String;

          ratings.add(rating);
          feedbacks.add(feedback);
        }

        // คำนวณค่าเฉลี่ยของคะแนน
        double averageRating = ratings.isNotEmpty ? ratings.reduce((value, element) => value + element) / ratings.length : 0.0;

        return ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.stars, color: buttoncolors),
              title: Row(
                children: [
                  const Text('Average Rating: '),
                  RatingBar(
                    initialRating: averageRating,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    ratingWidget: RatingWidget(
                      full: Icon(Icons.star, color: Colors.amber),
                      half: Icon(Icons.star_half, color: Colors.amber),
                      empty: Icon(Icons.star_border, color: Colors.amber),
                    ),
                    itemSize: 30,
                    onRatingUpdate: (rating) {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text('Feedbacks:'),
            for (String feedback in feedbacks) Text('- $feedback'),
          ],
        );
      }
    },
  );
}


}