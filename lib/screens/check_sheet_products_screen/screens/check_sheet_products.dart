import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:store_management/screens/check_sheet_products_screen/core/detail_bloc/product_bloc.dart';
import 'package:store_management/screens/check_sheet_products_screen/model/product_dto.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../constants/contains.dart';
import '../../../utils/utils.dart';

class CheckSheetProductsScreen extends StatefulWidget {
  final int branchId;

  const CheckSheetProductsScreen({Key? key, required this.branchId})
      : super(key: key);

  static const String routeName = '/check-sheet-products/:branchId';

  @override
  State<CheckSheetProductsScreen> createState() =>
      _CheckSheetProductsScreenState();
}

class _CheckSheetProductsScreenState extends State<CheckSheetProductsScreen> {
  late Barcode result;
  QRViewController? _qrViewController = null;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  late ScrollController _scrollController;
  late ProductBloc _productBloc;
  int _pageIndex = 1;
  int _pageSize = 50;
  bool _isShowCam = false;
  int indexFocus = -1;

  @override
  void initState() {
    _productBloc = BlocProvider.of<ProductBloc>(context);
    _productBloc.add(LoadProducts(
      branchId: widget.branchId,
      pageIndex: _pageIndex,
      pageSize: _pageSize,
    ));
    _scrollController = ScrollController();
    super.initState();
  }

  _scrollToItem(int index, final data) {
    setState(() {
      indexFocus = index;
    });
    if (index == -1) index = data.length - 1;
    try {
      if ((index * _scrollController.position.maxScrollExtent / data.length) ==
          _scrollController.position.pixels) {
        return;
      }
      _scrollController.animateTo(
        index * _scrollController.position.maxScrollExtent / data.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      print(e);
    }
  }

  initPermissions() async {
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
  }

  addBarCode(String barcode) {
    soundWhenScanned();
    var state = _productBloc.state as ProductLoaded;
    bool isExist = false;
    for (var i = 0; i < state.products.length; i++) {
      var element = state.products[i];
      if (element.code == barcode) {
        _productBloc.add(
          EditProduct(
            product: element.copyWith(
                inventoryCurrent: element.inventoryCurrent + 1),
            index: i,
          ),
        );
        _scrollToItem(i, state.products);
        isExist = true;
      }
    }
    if (!isExist) {
      try {
        setState(() {
          indexFocus = -1;
        });
        _productBloc.add(
          AddProduct(barcode: barcode, branchId: widget.branchId),
        );
      } catch (e) {}
    }
  }

  soundWhenScanned() async {
    final player = AudioPlayer();
    player.play(AssetSource('sounds/Scanner-Beep-Sound.wav'));
    print('Sound');
  }

  hideShowCamera() {
    setState(() {
      _isShowCam = !_isShowCam;
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      _qrViewController = controller;
    });
    if (!_isShowCam) {
      _qrViewController?.pauseCamera();
    } else {
      _qrViewController?.resumeCamera();
    }
    controller.scannedDataStream
        .debounce(const Duration(milliseconds: 300))
        .listen((scanData) {
      addBarCode(scanData.code!);
    });
  }

  _beforeDispose() {
    try {
      _productBloc.add(
        SaveToFileEvent(branchId: widget.branchId),
      );
    } catch (e) {}
  }

  @override
  void dispose() {
    //save data
    _beforeDispose();
    _scrollController.dispose();
    if (_qrViewController != null) {
      _qrViewController!.dispose();
    }
    super.dispose();
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      Fluttertoast.showToast(
        msg: 'Không có quyền bật camera',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const SCREEN_NAME = 'Kiểm tra tồn kho';
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(SCREEN_NAME, style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            onPressed: hideShowCamera,
            icon: Icon(
              _isShowCam ? Icons.close : Icons.camera_alt,
              color: Colors.white,
            ),
            tooltip: _isShowCam ? "Ẩn camera" : "Hiện camera",
          ),
          PopupMenuButton<String>(
            icon: const IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onPressed: null,
            ),
            elevation: 3.2,
            offset: const Offset(30, 50),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'SAVE',
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _productBloc.add(
                            SaveToFileEvent(branchId: widget.branchId),
                          );
                        },
                        icon:  const Icon(Icons.save, color: kPrimaryColor  ),
                      ),
                      const Text('Lưu dữ liệu'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'INFO',
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                        },
                        icon: const Icon(Icons.info, color: kPrimaryColor),
                      ),
                      const Text('Thông tin'),
                    ],
                  ),
                ),
              ];
            },
          ),
          //Làm mới
          IconButton(
            onPressed: () => {
              _scaffoldKey.currentState!.openEndDrawer(),
            },
            icon: const Icon(Icons.menu_open),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      endDrawer: _endDrawer(),
      endDrawerEnableOpenDragGesture: true,
      drawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: Column(
          children: [
            _isShowCam
                ? Expanded(
                    flex: 2,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      child: _buildQrView(context),
                      // child: AppBarcodeScannerWidget.defaultStyle(
                      //   resultCallback: addBarCode,
                      //   openManual: true,
                      // ),
                    ),
                  )
                : Container(),
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollNotification) {
                if (scrollNotification.metrics.pixels ==
                    scrollNotification.metrics.maxScrollExtent) {
                  if (_productBloc.state is ProductLoaded) {
                    _productBloc.add(LoadMoreProducts(
                        branchId: widget.branchId, pageSize: _pageSize));
                  }
                }
                return true;
              },
              child: Expanded(
                flex: 6,
                child: BlocBuilder<ProductBloc, ProductState>(
                  bloc: _productBloc,
                  builder: (context, state) {
                    if (state is ProductInitial) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (state is ProductLoaded) {
                      return state.products.isEmpty
                          ? _noDataSection("Không có dữ liệu")
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount:
                                  state.hasNext && state.isLoading != null
                                      ? state.products.length + 1
                                      : state.products.length,
                              addAutomaticKeepAlives: true,
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                if (index < state.products.length) {
                                  return _listProducts(
                                      product: state.products[index],
                                      index: index);
                                }
                                return _loadingSection();
                              });
                    }

                    if (state is Error) {
                      return const Center(
                        child: Text('Có lỗi xảy ra'),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  _endDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              color: Colors.blue,
              child: const Center(
                child: Text(
                  'Danh sách phiếu kiểm kho',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Phiếu kiểm kho $index'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    // var scanArea = (MediaQuery.of(context).size.width < 400 ||
    //     MediaQuery.of(context).size.height < 400)
    //     ? 150.0
    //     : 300.0;
    // // To ensure the Scanner view is properly sizes after rotation
    // // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10),
        onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
        formatsAllowed: _listFormats);
  }

  _noDataSection(String message) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Center(
              child: Text(
            message,
            style: const TextStyle(fontSize: 20),
          )),
        )
      ],
    );
  }

  _listProducts({required ProductDTO product, index}) {
    Color color = indexFocus == index
        ? Colors.red.withOpacity(0.2)
        : Colors.grey.withOpacity(0.2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                    child: Image.network(
                      product.image ?? '',
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 80,
                          height: 120,
                          child: Center(
                            child: Icon(Icons.image_not_supported),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 80,
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${product.name} - $index",
                      style: kTextAveHev14.copyWith(color: kColorBlack),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.start,
                    //   crossAxisAlignment: CrossAxisAlignment.center,
                    //   children: [
                    //     Container(
                    //       height:8,
                    //       width: 8,
                    //       decoration: BoxDecoration(
                    //           color: character.status=="Alive"?kColorGreen:kColorRed,
                    //           shape: BoxShape.circle
                    //       ),
                    //     ),
                    //     const SizedBox(width: kDefaultPadding/4,),
                    //     Text(character.status!,style: kTextAveHev14.copyWith(
                    //         color: kColorBlack,
                    //         fontSize: 12
                    //     ),),
                    //   ],
                    // ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      "Code: ${product.code!}",
                      style: kTextAveRom12.copyWith(color: kColorBlack),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 2,
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 5,
                    ),
                    Text(
                      "Giá: ${convertToVND(product.price)}",
                      style: kTextAveHev14.copyWith(
                          color: kColorBlack, fontSize: 12),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      "Tồn kho: ${(product.inventory!.toInt())}",
                      style: kTextAveHev14.copyWith(
                          color: kColorBlack.withOpacity(0.6), fontSize: 12),
                    ),
                    const SizedBox(
                      height: kDefaultPadding / 4,
                    ),
                    Text(
                      "Tồn thực tế: ${(product.inventoryCurrent.toInt())}",
                      style: kTextAveHev14.copyWith(
                          color: kColorBlack.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _loadingSection() {
    return const Center(child: CircularProgressIndicator());
  }
}

const _listFormats = [
  BarcodeFormat.aztec,

  /// CODABAR 1D format.
  /// Not supported in iOS
  BarcodeFormat.codabar,

  /// Code 39 1D format.
  BarcodeFormat.code39,

  /// Code 93 1D format.
  BarcodeFormat.code93,

  /// Code 128 1D format.
  BarcodeFormat.code128,

  /// Data Matrix 2D barcode format.
  BarcodeFormat.dataMatrix,

  /// EAN-8 1D format.
  BarcodeFormat.ean8,

  /// EAN-13 1D format.
  BarcodeFormat.ean13,

  /// ITF (Interleaved Two of Five) 1D format.
  BarcodeFormat.itf,

  /// MaxiCode 2D barcode format.
  /// Not supported in iOS.
  BarcodeFormat.maxicode,

  /// PDF417 format.
  BarcodeFormat.pdf417,

  /// QR Code 2D barcode format.
  BarcodeFormat.qrcode,

  /// RSS 14
  /// Not supported in iOS.
  BarcodeFormat.rss14,

  /// RSS EXPANDED
  /// Not supported in iOS.
  BarcodeFormat.rssExpanded,

  /// UPC-A 1D format.
  /// Same as ean-13 on iOS.
  BarcodeFormat.upcA,

  /// UPC-E 1D format.
  BarcodeFormat.upcE,

  /// UPC/EAN extension format. Not a stand-alone format.
  BarcodeFormat.upcEanExtension,
];
