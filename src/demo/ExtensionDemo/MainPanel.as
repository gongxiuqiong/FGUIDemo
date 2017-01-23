package demo.ExtensionDemo
{
	import fairygui.GComponent;
	import fairygui.GList;
	import fairygui.GRoot;
	import fairygui.UIPackage;

	public class MainPanel
	{
		private var _view: GComponent;
		private var _list: GList;
		
		public function MainPanel()
		{
			this._view = UIPackage.createObject("Extension", "Main").asCom;
			this._view.setSize(GRoot.inst.width, GRoot.inst.height);
			GRoot.inst.addChild(this._view);
			
			this._list = this._view.getChild("mailList").asList;
			var i:int;
			for(i = 0; i < 10; i++)
			{
				var item:MailItem = this._list.addItemFromPool() as MailItem;
				item.setFetched(i % 3 == 0);
				item.setRead(i % 2 == 0);
				item.setTime("5 Nov 2015 16:24:33");
				item.title = "Mail title here";
			}
	
			this._list.ensureBoundsCorrect();
			var delay: Number = 0;
			for(i = 0; i < 10; i++)
			{
				var _item:MailItem = this._list.getChildAt(i) as MailItem;
				if(this._list.isChildInView(_item))
				{
					_item.playEffect(delay);
					delay += 2;
				}
				else
					break;
			}
		}
	}
}