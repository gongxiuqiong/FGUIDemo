package demo.VirtualListDemo
{
	import fairygui.GComponent;
	import fairygui.GList;
	import fairygui.GObject;
	import fairygui.GRoot;
	import fairygui.UIPackage;
	
	import laya.utils.Handler;

	public class MainPanel
	{
		private var _view: GComponent;
		private var _list:GList;
		
		public function MainPanel()
		{
			this._view = UIPackage.createObject("VirtualList","Main").asCom;
			this._view.setSize(GRoot.inst.width,GRoot.inst.height);
			GRoot.inst.addChild(this._view);
			
			this._view.getChild("n6").onClick(this,function():void { this._list.addSelection(500, true); });
			this._view.getChild("n7").onClick(this,function():void { this._list.scrollPane.scrollTop(); });
			this._view.getChild("n8").onClick(this,function():void { this._list.scrollPane.scrollBottom(); });
			
			this._list = this._view.getChild("mailList").asList;
			this._list.setVirtual();
			
			this._list.itemRenderer = Handler.create(this, this.renderListItem, null, false);
			this._list.numItems = 1000;
		}
		
		private function renderListItem(index:Number, obj:GObject):void {
			var item:MailItem = obj as MailItem;
			item.setFetched(index % 3 == 0);
			item.setRead(index % 2 == 0);
			item.setTime("5 Nov 2015 16:24:33");
			item.title = index + " Mail title here";
		}
	}
}