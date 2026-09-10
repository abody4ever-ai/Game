import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const LidoApp());

enum PlayerColor { red, blue, green, yellow }
extension PlayerColorX on PlayerColor {
  Color get color => [const Color(0xffb73532), const Color(0xff2f65a3), const Color(0xff3e7d4b), const Color(0xffc89b27)][index];
  String get ar => ['أحمر','أزرق','أخضر','أصفر'][index];
}

class Stone {
  Stone(this.id, this.color);
  final int id; final PlayerColor color; int step = -1;
  bool get home => step < 0; bool get done => step >= 57;
}

class LidoGame {
  LidoGame({this.players = 2, this.level = 2}) {
    for (final c in PlayerColor.values) for (var i=0;i<4;i++) stones.add(Stone(i,c));
  }
  final Random rng = Random(); final List<Stone> stones=[]; final List<int> rolls=[];
  int players, level, turn=0; bool over=false; int winner=-1;
  final safe={1,9,14,22,27,35,40,48};
  List<Stone> mine() => stones.where((s)=>s.color.index==turn).toList();
  int global(Stone s){ if(s.home || s.done)return -1; return ([0,13,26,39][s.color.index]+s.step)%52; }
  List<Stone> at(int p)=>stones.where((s)=>global(s)==p).toList();
  bool blockadeAt(int p, PlayerColor? enemy){final x=at(p).where((s)=>enemy==null||s.color!=enemy).toList(); return x.length>=2 && x.every((s)=>s.color==x.first.color);}
  List<Stone> group(Stone s)=>s.home?[]:at(global(s)).where((x)=>x.color==s.color).toList();
  bool isBlock(Stone s)=>group(s).length>=2;

  bool canMove(Stone s,int d){
    if(s.done || d<1)return false;
    if(s.home)return d==6;
    if(s.step+d>57)return false;
    if(isBlock(s))return true; // السد يعبر السد
    final from=global(s);
    for(var i=1;i<=min(d,56-s.step);i++) if(blockadeAt((from+i)%52,s.color)) return false;
    return true;
  }
  void roll(){ if(over)return; rolls.add(rng.nextInt(6)+1); }
  bool move(Stone s,int d){
    if(!rolls.contains(d)||!canMove(s,d))return false;
    final g=group(s); final block=g.length>=2;
    if(block && d.isEven){ for(final x in g)x.step=min(57,x.step+d); }
    else { s.step=s.home?0:s.step+d; }
    _eat(s);
    rolls.remove(d);
    if(mine().every((x)=>x.done)){over=true;winner=turn;}
    else if(rolls.isEmpty) turn=(turn+1)%players;
    return true;
  }
  void _eat(Stone moved){
    if(moved.home||moved.done)return; final p=global(moved); if(safe.contains(p))return;
    final e=at(p).where((x)=>x.color!=moved.color).toList(); if(e.isEmpty)return;
    final by=<PlayerColor,List<Stone>>{}; for(final x in e)by.putIfAbsent(x.color,()=>[]).add(x);
    for(final x in by.values) for(final s in x) s.step=-1; // السد يأكل سدًا كاملًا
  }
}

class LidoApp extends StatelessWidget { const LidoApp({super.key}); @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'ليدو Lido',theme:ThemeData(useMaterial3:true,fontFamily:'sans-serif'),home:const Home()); }

class Home extends StatelessWidget { const Home({super.key});
  @override Widget build(BuildContext c)=>Scaffold(backgroundColor:const Color(0xff3b2415),body:SafeArea(child:Center(child:Padding(padding:const EdgeInsets.all(22),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
    Container(width:110,height:110,decoration:BoxDecoration(color:const Color(0xffa96f3c),shape:BoxShape.circle,border:Border.all(color:const Color(0xffe3b778),width:5),boxShadow:const[BoxShadow(blurRadius:15,color:Colors.black54)]),child:const Icon(Icons.casino,size:64,color:Colors.white)),
    const SizedBox(height:18),const Text('ليدو',style:TextStyle(color:Color(0xffffd79a),fontSize:46,fontWeight:FontWeight.w900)),const Text('LIDO',style:TextStyle(color:Colors.white70,fontSize:20,letterSpacing:6)),const SizedBox(height:38),
    _btn(c,'ضد الكمبيوتر',Icons.smart_toy,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const Setup(ai:true)))),
    const SizedBox(height:12),_btn(c,'لاعبان على نفس الجهاز',Icons.people,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const Setup(ai:false)))),
  ])))); }
  Widget _btn(BuildContext c,String t,IconData i,VoidCallback f)=>SizedBox(width:300,height:54,child:ElevatedButton.icon(onPressed:f,icon:Icon(i),label:Text(t,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))));
}

class Setup extends StatefulWidget { const Setup({super.key,required this.ai}); final bool ai; @override State<Setup> createState()=>_SetupState(); }
class _SetupState extends State<Setup>{ int players=2,level=2;
  @override Widget build(BuildContext c)=>Scaffold(backgroundColor:const Color(0xff3b2415),appBar:AppBar(title:const Text('إعداد اللعبة'),backgroundColor:const Color(0xff7d4f2a),foregroundColor:Colors.white),body:Padding(padding:const EdgeInsets.all(22),child:Column(children:[
    const Align(alignment:Alignment.centerRight,child:Text('عدد اللاعبين',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold))),
    const SizedBox(height:10),Wrap(spacing:10,children:[2,3,4].map((n)=>ChoiceChip(label:Text('$n'),selected:players==n,onSelected:(_)=>setState(()=>players=n))).toList()),
    if(widget.ai) ...[const SizedBox(height:30),const Align(alignment:Alignment.centerRight,child:Text('مستوى الكمبيوتر',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.bold))),const SizedBox(height:10),Wrap(spacing:10,children:[1,2,3].map((n)=>ChoiceChip(label:Text(['سهل','متوسط','صعب'][n-1]),selected:level==n,onSelected:(_)=>setState(()=>level=n))).toList())],
    const Spacer(),SizedBox(width:300,height:55,child:ElevatedButton(onPressed:()=>Navigator.pushReplacement(c,MaterialPageRoute(builder:(_)=>GamePage(players:players,level:level))),child:const Text('ابدأ اللعب',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)))),const SizedBox(height:20)
  ])); }
}

class GamePage extends StatefulWidget { const GamePage({super.key,required this.players,required this.level}); final int players,level; @override State<GamePage> createState()=>_GamePageState(); }
class _GamePageState extends State<GamePage>{ late LidoGame g; int? die; String msg='ارمِ النرد'; bool busy=false;
 @override void initState(){super.initState();g=LidoGame(players:widget.players,level:widget.level);}
 void setMsg(String x)=>setState(()=>msg=x);
 Future<void> roll(){ if(g.over||busy||g.turn!=0)return Future.value(); g.roll(); setState(()=>die=null); if(g.rolls.last==6){setMsg('٦ — رمية إضافية'); return Future.delayed(const Duration(milliseconds:350),roll);} setMsg('اختر رقمًا ثم حجرًا'); return Future.value(); }
 void tapStone(Stone s){ if(die==null){setMsg('اختر رقمًا من الأعلى أولاً');return;} if(g.move(s,die!)){setState(()=>die=null); if(g.over){setMsg('مبروك! ${PlayerColor.values[g.winner].ar} فاز');} else if(g.turn!=0){_ai();} else setMsg(g.rolls.isEmpty?'ارمِ النرد':'اختر حجرًا');} else setMsg('الحركة غير مسموحة'); }
 Future<void> _ai() async { if(busy)return; busy=true; await Future.delayed(const Duration(milliseconds:500)); while(!g.over&&g.turn!=0){g.roll(); if(g.rolls.last!=6)break; await Future.delayed(const Duration(milliseconds:300));} if(g.over){busy=false;return;} var best; int bd=0,score=-9999; for(final d in g.rolls){for(final s in g.mine())if(g.canMove(s,d)){var sc=s.home?100:(s.done?1000:s.step); if(widget.level==3)sc+=d*3; if(sc>score){score=sc;best=s;bd=d;}}} if(best!=null)g.move(best,bd); else g.rolls.clear(); if(!g.over&&g.turn==0)setMsg('دورك'); busy=false; setState((){}); }
 @override Widget build(BuildContext c)=>Scaffold(backgroundColor:const Color(0xff5b371f),appBar:AppBar(title:const Text('ليدو Lido'),centerTitle:true,backgroundColor:const Color(0xff81522d),foregroundColor:Colors.white),body:SafeArea(child:Column(children:[const SizedBox(height:6),Text('',style:TextStyle(color:Colors.white)),Text(msg,style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.bold)),const SizedBox(height:5),Expanded(child:Center(child:AspectRatio(aspectRatio:1,child:Board(g:g,onTap:tapStone)))),if(g.rolls.isNotEmpty)Wrap(spacing:7,children:[...g.rolls.asMap().entries.map((e)=>ChoiceChip(label:Text('${e.value}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),selected:die==e.value,onSelected:(_)=>setState(()=>die=e.value)))]),const SizedBox(height:6),Row(mainAxisAlignment:MainAxisAlignment.center,children:[ElevatedButton.icon(onPressed:(g.turn==0&&!busy)?roll:null,icon:const Icon(Icons.casino),label:const Text('ارمِ النرد')),const SizedBox(width:10),OutlinedButton(onPressed:()=>Navigator.pop(c),child:const Text('القائمة'))]),const SizedBox(height:8)])); }
}

class Board extends StatelessWidget { const Board({super.key,required this.g,required this.onTap}); final LidoGame g; final void Function(Stone) onTap;
 @override Widget build(BuildContext c)=>LayoutBuilder(builder:(c,b){final sz=min(b.maxWidth,b.maxHeight);return Container(width:sz,height:sz,padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:const Color(0xffb87945),border:Border.all(color:const Color(0xff3a2111),width:8),borderRadius:BorderRadius.circular(18),boxShadow:const[BoxShadow(blurRadius:12,offset:Offset(0,6),color:Colors.black54)]),child:CustomPaint(painter:BoardPainter(g),child:Stack(children:[for(final s in g.stones)if(!s.home&&!s.done)Positioned(left:point(g.global(s),sz).dx-14,top:point(g.global(s),sz).dy-14,child:GestureDetector(onTap:()=>onTap(s),child:StoneView(s)))])));});
 Offset point(int i,double size){final cell=size/15; final ring=<Offset>[]; for(var x=0;x<15;x++)ring.add(Offset((x+.5)*cell,7.5*cell)); for(var y=0;y<15;y++)ring.add(Offset(14.5*cell,(y+.5)*cell)); for(var x=14;x>=0;x--)ring.add(Offset((x+.5)*cell,14.5*cell)); for(var y=14;y>=0;y--)ring.add(Offset(.5*cell,(y+.5)*cell)); return ring[i%ring.length];}
}
class StoneView extends StatelessWidget{const StoneView(this.s,{super.key});final Stone s;@override Widget build(BuildContext c)=>Container(width:28,height:28,decoration:BoxDecoration(shape:BoxShape.circle,color:s.color.color,border:Border.all(color:Colors.white,width:2),boxShadow:const[BoxShadow(blurRadius:4,offset:Offset(1,2),color:Colors.black54)]),child:Center(child:Text('${s.id+1}',style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.bold))));}
class BoardPainter extends CustomPainter{BoardPainter(this.g);final LidoGame g;@override void paint(Canvas c,Size s){final p=Paint()..style=PaintingStyle.fill;final cell=s.width/15; for(var y=0;y<15;y++)for(var x=0;x<15;x++){p.color=((x+y)%2==0)?const Color(0xffd2a06a):const Color(0xffc28c56);c.drawRect(Rect.fromLTWH(x*cell,y*cell,cell,cell),p);} for(var i=0;i<4;i++){final r=Rect.fromLTWH((i%2)*7*cell,(i~/2)*7*cell,7*cell,7*cell);p.color=PlayerColor.values[i].color.withOpacity(.75);c.drawRRect(RRect.fromRectAndRadius(r,Radius.circular(12)),p);} p.color=const Color(0xffefd5a2);c.drawRect(Rect.fromLTWH(7*cell,0,cell,15*cell),p);c.drawRect(Rect.fromLTWH(0,7*cell,15*cell,cell),p); final center=Offset(7.5*cell,7.5*cell);p.color=const Color(0xff8b5a32);c.drawCircle(center,2.0*cell,p);p.color=Colors.white.withOpacity(.9);c.drawCircle(center,1.45*cell,p);p.color=const Color(0xff9b6a3b);c.drawCircle(center,.95*cell,p);}
 @override bool shouldRepaint(covariant BoardPainter old)=>true;}
