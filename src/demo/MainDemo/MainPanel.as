package demo.MainDemo
{
	import fairygui.Controller;
	import fairygui.DragDropManager;
	import fairygui.GButton;
	import fairygui.GComponent;
	import fairygui.GGraph;
	import fairygui.GList;
	import fairygui.GObject;
	import fairygui.GRoot;
	import fairygui.PopupMenu;
	import fairygui.UIPackage;
	import fairygui.Window;
	
	import laya.events.Event;
	import laya.maths.Point;
	import laya.maths.Rectangle;
	import laya.utils.Utils;

	public class MainPanel
	{
		private var _view: GComponent;
		private var _backBtn: GObject;
		private var _demoContainer: GComponent;
		private var _cc: Controller;
		
		private var _demoObjects: Object;

		public function MainPanel()
		{
			this._view = UIPackage.createObject("Basic", "Main").asCom;
			this._view.setSize(GRoot.inst.width, GRoot.inst.height);
			GRoot.inst.addChild(this._view);
			
			this._backBtn = this._view.getChild("btn_Back");
			this._backBtn.visible = false;
			this._backBtn.onClick(this, this.onClickBack);
			
			this._demoContainer = this._view.getChild("container").asCom;
			this._cc = this._view.getController("c1");
			
			var cnt: Number = this._view.numChildren;
			for(var i: Number = 0;i < cnt;i++) {
				var obj: GObject = this._view.getChildAt(i);
				if(obj.group != null && obj.group.name == "btns")
					obj.onClick(this, this.runDemo);
			}
			
			this._demoObjects = {};
		}
		
		private function runDemo(evt: Event): void {
			var type: String = GObject.cast(evt.currentTarget).name.substr(4);
			var obj: GComponent = this._demoObjects[type];
			if(obj == null) {
				obj = UIPackage.createObject("Basic","Demo_" + type).asCom;
				this._demoObjects[type] = obj;
			}
			
			this._demoContainer.removeChildren();
			this._demoContainer.addChild(obj);
			this._cc.selectedIndex = 1;
			this._backBtn.visible = true;
			
			switch(type) {
				case "Button":
					this.playButton();
					break;
				
				case "Text":
					this.playText();
					break;
				
				case "Window":
					this.playWindow();
					break;
				
				case "Popup":
					this.playPopup();
					break;
				
				case "Drag&Drop":
					this.playDragDrop();
					break;
				
				case "Depth":
					this.playDepth();
					break;
				
				case "Grid":
					this.playGrid();
					break;
				
				case "ProgressBar":
					this.playProgressBar();
					break;
			}
		}
		
		private function onClickBack(evt: Event): void {
			this._cc.selectedIndex = 0;
			this._backBtn.visible = false;
		}
		
		//------------------------------
		private function playButton(): void {
			var obj: GComponent = this._demoObjects["Button"];
			obj.getChild("n34").onClick(this, this.__clickButton);
		}
		
		private function __clickButton(): void {
			console.log("click button"); 
		}
		
		//------------------------------
		private function playText(): void {
			var obj: GComponent = this._demoObjects["Text"];
			//obj.getChild("n12").asRichTextField.div.on(laya.events.Event.LINK,this,this.__clickLink);
			Laya.stage.on(laya.events.Event.LINK,this,this.__clickLink);
			obj.getChild("n22").onClick(this, this.__clickGetInput);
		}
		
		private function __clickLink(link:String): void {
			var obj: GComponent = this._demoObjects["Text"];
			obj.getChild("n12").text = "[img]ui://9leh0eyft9fj5f[/img][color=#FF0000]你点击了链接[/color]：" + link;
		}
		
		private function __clickGetInput():void {
			var obj: GComponent = this._demoObjects["Text"];
			obj.getChild("n21").text = obj.getChild("n19").text;
		}
		
		//------------------------------
		private var _winA: Window;
		private var _winB: Window;
		private function playWindow(): void {
			var obj: GComponent = this._demoObjects["Window"];
			obj.getChild("n0").onClick(this, this.__clickWindowA);
			obj.getChild("n1").onClick(this, this.__clickWindowB);
		}
		
		private function __clickWindowA(): void {
			if(this._winA == null)
			this._winA = new WindowA();
			this._winA.show();
		}
		
		private function __clickWindowB(): void {
			if(this._winB == null)
			this._winB = new WindowB();
			this._winB.show();
		}
		
		//------------------------------
		private var _pm: PopupMenu;
		private var _popupCom: GComponent;
		private function playPopup(): void {
			if(this._pm == null) {
				this._pm = new PopupMenu();
				this._pm.addItem("Item 1");
				this._pm.addItem("Item 2");
				this._pm.addItem("Item 3");
				this._pm.addItem("Item 4");
				
				if(this._popupCom == null) {
					this._popupCom = UIPackage.createObject("Basic","Component12").asCom;
					this._popupCom.center();
				}
			}
			
			var obj: GComponent = this._demoObjects["Popup"];
			var btn: GObject = obj.getChild("n3");
			btn.onClick(this, this.__clickPopup1);
			
			var btn2: GObject = obj.getChild("n5");
			btn2.onClick(this, this.__clickPopup2);
		}
		
		private function __clickPopup1(evt:laya.events.Event):void {
			var btn: GObject = GObject.cast(evt.currentTarget);
			this._pm.show(btn,true);
		}
		
		private function __clickPopup2(): void {
			GRoot.inst.showPopup(this._popupCom);
		}
		
		//------------------------------
		private function playDragDrop(): void {
			var obj: GComponent = this._demoObjects["Drag&Drop"];
			var btnA: GObject = obj.getChild("a");
			btnA.draggable = true;
			
			var btnB: GButton = obj.getChild("b").asButton;
			btnB.draggable = true;
			btnB.on(fairygui.Events.DRAG_START,this,this.__onDragStart);
			
			var btnC: GButton = obj.getChild("c").asButton;
			btnC.icon = null;
			btnC.on(fairygui.Events.DROP,this,this.__onDrop);
			
			var btnD: GObject = obj.getChild("d");
			btnD.draggable = true;
			var bounds: GObject = obj.getChild("bounds");
			var rect: Rectangle = new  Rectangle();
			bounds.localToGlobalRect(0,0,bounds.width,bounds.height,rect);
			GRoot.inst.globalToLocalRect(rect.x,rect.y,rect.width,rect.height,rect);
			
			//因为这时候面板还在从右往左动，所以rect不准确，需要用相对位置算出最终停下来的范围
			rect.x -= obj.parent.x;
			
			btnD.dragBounds = rect;
		}
		
		private function __onDragStart(evt:laya.events.Event):void {
			var btn: GButton = GObject.cast(evt.currentTarget) as GButton;
			btn.stopDrag();//取消对原目标的拖动，换成一个替代品
			DragDropManager.inst.startDrag(btn,btn.icon,btn.icon);
		}
		
		private function __onDrop(data:String, evt:laya.events.Event):void {
			var btn: GButton = GObject.cast(evt.currentTarget) as GButton;
			btn.icon = data;
		}
		
		//------------------------------
		private function playDepth(): void {
			var obj: GComponent = this._demoObjects["Depth"];
			var testContainer: GComponent = obj.getChild("n22").asCom;
			var fixedObj: GObject = testContainer.getChild("n0");
			fixedObj.sortingOrder = 100;
			fixedObj.draggable = true;
			
			var numChildren: int = testContainer.numChildren;
			var i: int = 0;
			while(i < numChildren) {
				var child: GObject = testContainer.getChildAt(i);
				if(child != fixedObj) {
					testContainer.removeChildAt(i);
					numChildren--;
				}
				else
					i++;
			}
			var startPos: Point = new Point(fixedObj.x,fixedObj.y);
			
			obj.getChild("btn0").onClick(this, this.__click1, [obj, startPos]);
			obj.getChild("btn1").onClick(this, this.__click2, [obj, startPos]);
		}
		
		private function __click1(obj:GComponent, startPos:Point):void {
			var graph: GGraph = new GGraph();
			startPos.x += 10;
			startPos.y += 10;
			graph.setXY(startPos.x,startPos.y);
			graph.setSize(150,150);
			graph.drawRect(1,"#000000","#FF0000");
			obj.getChild("n22").asCom.addChild(graph);
		}
		
		private function __click2(obj:GComponent, startPos:Point):void {
//			var obj: GComponent = this._demoObjects["Depth"];
			var graph: GGraph = new GGraph();
			startPos.x += 10;
			startPos.y += 10;
			graph.setXY(startPos.x,startPos.y);
			graph.setSize(150,150);
			graph.drawRect(1,"#000000","#00FF00");
			graph.sortingOrder = 200;
			obj.getChild("n22").asCom.addChild(graph);
		}
		
		//------------------------------
		private function playGrid(): void {
			var obj: GComponent = this._demoObjects["Grid"];
			var list1:GList = obj.getChild("list1").asList;
			list1.removeChildrenToPool();
			var testNames: Array = ["苹果手机操作系统","安卓手机操作系统","微软手机操作系统","微软桌面操作系统","苹果桌面操作系统","未知操作系统"];
			var testColors: Array = [ 0xFFFF00,0xFF0000,0xFFFFFF,0x0000FF ];
			var cnt:int = testNames.length;
			var i:int;
			var item:GButton;
			for(i = 0;i < cnt; i++)
			{
				item = list1.addItemFromPool().asButton;
				item.getChild("t0").text = "" + (i + 1);
				item.getChild("t1").text = testNames[i];
				item.getChild("t2").asTextField.color = Utils.toHexColor(testColors[Math.floor(Math.random()*4)]);
				item.getChild("star").asProgress.value = (Math.floor(Math.random() * 3)+1) / 3 * 100;
			}
			
			var list2: GList = obj.getChild("list2").asList;
			list2.removeChildrenToPool();
			for(i = 0;i < cnt;i++)
			{
				item = list2.addItemFromPool().asButton;
				item.getChild("cb").asButton.selected = false;
				item.getChild("t1").text = testNames[i];
				item.getChild("mc").asMovieClip.playing = i % 2 == 0;
				item.getChild("t3").text = "" + Math.floor(Math.random() * 10000)
			}
		}
		
		//---------------------------------------------
		private function playProgressBar():void
		{
			var obj:GComponent = this._demoObjects["ProgressBar"];
			Laya.timer.frameLoop(2, this, this.__playProgress);
			obj.on(laya.events.Event.UNDISPLAY, this, this.__removeTimer);
		}
		
		private function __removeTimer():void
		{
			Laya.timer.clear(this, this.__playProgress);
		}
		
		private function __playProgress():void
		{
			var obj:GComponent = this._demoObjects["ProgressBar"];
			var cnt:int = obj.numChildren;
			for (var i:int = 0; i < cnt; i++)
			{
				var child:fairygui.GProgressBar = obj.getChildAt(i) as fairygui.GProgressBar;
				if (child != null)
				{
					child.value += 1;
					if (child.value > child.max)
						child.value = 0;
				}
			}
		}
	}
}