import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:control/vistas/menu.dart';
import 'package:control/modelos/Ventas.dart';
import 'package:control/controlador/InsertarVenta.dart';
import 'package:control/vistas/ventas/recoleccion.dart';
import 'package:workmanager/workmanager.dart';

class RecoleccionView extends StatefulWidget {
  RecoleccionView({this.boton});
  final bool boton;
  @override
  _RecoleccionViewState createState() => _RecoleccionViewState();
}

class _RecoleccionViewState extends State<RecoleccionView> with WidgetsBindingObserver{
  bool boton= true;
  bool ordenar= false;
  DateTime now = new DateTime.now();
  final format = DateFormat("dd/MM/yyyy");
  TextEditingController  filtro = new TextEditingController();

  @override
  void didUpdateWidget(RecoleccionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      //widget.boton==true?boton=true:boton=false;
    });
  }
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    widget.boton==true?boton=true:boton=false;
  }
  void callbackDispatcher() {
    Workmanager.executeTask((task, inputData) async {
    if(task=='_actualizar'){
        _actualizar();
    }
    ///session_p ();
    return Future.value(true);
    });
  }
  void showConnectivitySnackBar(ConnectivityResult result) {
    final hasInternet = result != ConnectivityResult.none;
    // final message = hasInternet
    //     ? 'You have again ${result.toString()}'
    //     : 'You have no internet';
    //final color = hasInternet ? Colors.green : Colors.red;
    if(hasInternet){
      _actualizar();
    }
    
    //Utils.showTopSnackBar(context, message, color);
  }

  _actualizar(){  
    var session= Insertar();
    session.enviarClientes(actualizar: false).then((_){
      session.actualizarVentas().then((_){
        session.enviarHistorial().then((_){
          session.baseConsulta().then((_){
            session.enviarGastos().then((_){
            });
          });
        });
      });
    });
  }

  Future<List<Ventas>> ventas(filtro){
    var insertar = Insertar();
    String ordenConsulta;
    if(ordenar==true)
    {
      ordenConsulta='Cliente.nombre';
    }else{
      ordenConsulta='Venta.orden';
    }
    return insertar.consultarRecoleccion(filtro:filtro,ruta:boton,orden:ordenConsulta);
  }

  formItemsDesign(icon, item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical:4),
      child: Card(child: ListTile(
        leading:IconButton(
          icon: const Icon(Icons.autorenew_rounded),
          tooltip: 'B??squeda',
          onPressed: () {
            setState(() {
              ordenar=!ordenar;
              ventas(filtro.text);
            });
          },
        ), title: item)),
    );
  }

  Widget cardCuenta(Ventas item){
    String fechaComparar=format.format((DateTime.fromMillisecondsSinceEpoch(item.fecha,isUtc:false))).toString();
    String fechaHoy=format.format(now);
    DateTime fecha= DateTime.fromMillisecondsSinceEpoch(item.fecha);
    int diffDays = now.difference(fecha).inDays;
    double diferencia = diffDays-item.numeroCuota;
    String motivo=item.motivo;
    Icon iconoEstado;
    Icon icono;
    Color color;

    if(fechaComparar == fechaHoy)
    {
      icono=Icon(Icons.person, size:28,color:Colors.black);
    }else if(diferencia <=3)
    {
      icono=Icon(Icons.thumb_up, size:28,color:Colors.green);
    }else if(diferencia > 3 && diferencia < 6 )
    {
      icono=Icon(Icons.thumbs_up_down , size:28,color:Colors.yellow);
    }else if(diferencia >=6){
      icono=Icon(Icons.thumb_down_sharp, size:28,color:Colors.red);
    }

    if(motivo=="abono" || motivo=="pago"|| motivo=="Prestamo"){
      iconoEstado=Icon(Icons.check, size:20,color:Colors.green);
      color=Colors.green;
    }else if(motivo=="No pago"|| motivo=="No encontrado"|| motivo=="Pasar ma??ana" || motivo=="Bloqueado"){
      iconoEstado=Icon(Icons.clear, size:20,color:Colors.red);
      color=Colors.white;
    }
    print(diffDays);
    return 
    Card(
      child:
      ListTile(
        leading:icono,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.nombre+" "+item.primerApellido,style: TextStyle(
              fontSize: 17,)
            ),
            Row(
              children: [
                Text("D:"+item.idCliente+" "+item.alias,style: TextStyle(
                  fontSize: 15,)
                ),
              ],
            )
          ],
        ),
        subtitle:Row(
          children: [
            Text((item.saldo/item.valorCuota).toStringAsFixed(1),style: TextStyle(fontWeight:FontWeight.bold,color: Colors.black,fontSize:18,)),
            Text(" / ",style: TextStyle(fontWeight:FontWeight.bold,color: Colors.black,fontSize:18,)),
            Text(item.saldo.toStringAsFixed(1),style: TextStyle(fontWeight:FontWeight.bold,color: Colors.black,fontSize:18,)),
            Text(" / ",style: TextStyle(fontWeight:FontWeight.bold,color: Colors.black,fontSize:18,)),
            Text(item.valorCuota.toStringAsFixed(1),style: TextStyle(fontWeight:FontWeight.bold,color: Colors.black,fontSize:18,)),
            iconoEstado,
            SizedBox(width: 12.0),
            Text(item.valorDia.toStringAsFixed(1),style: TextStyle(fontSize:18,color: color)),
          ],
        ), 
        onTap: () async{
          Workmanager.initialize(
          callbackDispatcher, // The top level function, aka callbackDispatcher
          isInDebugMode: true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
        );
        final result = await Connectivity().checkConnectivity();
        showConnectivitySnackBar(result);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement( context, MaterialPageRoute( builder: (context) => Recoleccion(data: item,),)); }
          );
        },
      )
    );
  }
  Widget build(BuildContext context) {
    //Size size = MediaQuery.of(context).size;
    var menu = new Menu();
    return WillPopScope(
      onWillPop: () async => false,
      child:
      SafeArea(
        top: false,
        child: Scaffold(
          appBar: new AppBar(title: new Text('Ruta'),actions: <Widget>[
          ],
          ),
          drawer: menu,
          body: body(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                boton=!boton;      
              });
            },
            child: boton?const Icon(Icons.person):const Icon(Icons.two_wheeler_rounded),
            //backgroundColor: Color.fromRGBO(56, 124, 43, 1.0),
          ),
      
        )
      ),
    );
  }
  Widget body(){
    return Column(
      children: [
        formItemsDesign(
          Icons.search,
          TextFormField(
            controller: filtro,
            decoration: new InputDecoration(
              labelText: 'Buscar',
            ),
            onChanged: (text){
              setState(() {
                ventas(text);
              });
            },
          )
        ),
        Expanded(
          child: listaVentas()
        )
      ],
    );
  }
  FutureBuilder<List<Ventas>> listaVentas() {
    return FutureBuilder<List<Ventas>>(
      //llamamos al m??todo, que est?? en la carpeta db file database.dart
      future: ventas(filtro.text),
      builder: (BuildContext context, AsyncSnapshot<List<Ventas>> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            physics: BouncingScrollPhysics(),
            //Count all records
            itemCount: snapshot.data.length,
            // todos los registros que est??n en la tabla del usuario se pasan a un elemento Elemento del usuario = snapshot.data [index];
            itemBuilder: (BuildContext context, int index){
              Ventas item = snapshot.data[index];
              //delete one register for id
              return cardCuenta(item);
              // Dismissible(
              //   key: UniqueKey(),
              //   background: Container(color: Colors.red),
              //   onDismissed: (diretion) {
              //     //DatabaseProvider.db.eliminarId(item.id,"producto");
              //   },
              //   //Ahora pintamos la lista con todos los registros
              //   child:cardCuenta(item),
              // );
            },
          );
        }else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  @override
  void dispose() {
    filtro.dispose();
    super.dispose();
  }
}