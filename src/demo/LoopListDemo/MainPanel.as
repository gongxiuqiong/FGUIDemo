package demo.LoopListDemo
{
	import fairygui.Events;
	import fairygui.GButton;
	import fairygui.GComponent;
	import fairygui.GList;
	import fairygui.GObject;
	import fairygui.GRoot;
	import fairygui.UIPackage;
	
	import laya.utils.Handler;

	public class MainPanel
	{
		private var _view:GComponent;
		private var _list:GList;
		
		public function MainPanel()
		{
			this._view = UIPackage.createObject("LoopList", "Main") as GComponent;
			this._view.setSize(GRoot.inst.width, GRoot.inst.height);
			GRoot.inst.addChild(this._view);
			
			this._list = this._view.getChild("list") as GList;
			this._list.setVirtualAndLoop();
			
			this._list.itemRenderer = Handler.create(this, renderListItem, null, false);
			this._list.numItems = 5;
			this._list.on(Events.SCROLL, this, doSpecialEffect);
		}
		
		private function doSpecialEffect():void
		{
			var midx:Number = this._list.scrollPane.posX + this._list.viewWidth/2;
			var cnt:Number = this._list.numChildren;
			for(var i:int = 0; i < cnt; i++)
			{
				var obj:GObject = this._list.getChildAt(i);
				var dist:Number = Math.abs(midx - obj.x - obj.width/2);
				if(dist > obj.width)
					obj.setScale(1, 1);
				else
				{
					var ss:Number = 1 + (1 - dist/ obj.width) * 0.24;
					obj.setScale(ss, ss);
				}
			}
			
			this._view.getChild("n3").text = "" + ((this._list.getFirstChildInView() + 1) % this._list.numItems);
		}
		
		private function renderListItem(index:int, obj:GObject):void
		{
			var item:GButton = obj as GButton;
			item.setPivot(0.5, 0.5);
			item.icon = UIPackage.getItemURL("LoopList", "n" + (index + 1));
		}
	}
}