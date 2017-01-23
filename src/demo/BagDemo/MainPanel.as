package demo.BagDemo
{
	import fairygui.Events;
	import fairygui.GButton;
	import fairygui.GComponent;
	import fairygui.GList;
	import fairygui.GObject;
	import fairygui.GRoot;
	import fairygui.UIPackage;

	public class MainPanel
	{
		private var  _view: GComponent;
		private var _list: GList;
		
		public function MainPanel()
		{
			this._view = UIPackage.createObject("Bag","Main").asCom;
			this._view.setSize(GRoot.inst.width,fairygui.GRoot.inst.height);
			GRoot.inst.addChild(this._view);
			
			this._list = this._view.getChild("list").asList;
			this._list.on(Events.CLICK_ITEM, this, this.__clickItem);	
			
			for(var i:int = 0;i < 10; i++)
			{
				var button:GButton = this._list.getChildAt(i).asButton;
				button.icon = "res/bag/i" + Math.floor(Math.random() * 10) + ".png";
				button.title = "" + Math.floor(Math.random() * 100);
			}
		}
		
		private function __clickItem(itemObject:GObject):void
		{
			var item:GButton = itemObject as GButton;
			this._view.getChild("n3").asLoader.url = item.icon;
			this._view.getChild("n5").text = item.icon;
		}
	}
}