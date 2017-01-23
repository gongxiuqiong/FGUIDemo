package demo.MainDemo
{
	import fairygui.Window;
	
	public class WindowA extends Window
	{
		public function WindowA()
		{
			super();
		}
		
		override protected function  onInit():void {
			this.contentPane = fairygui.UIPackage.createObject("Basic","WindowA").asCom;
			this.center();
		}
		
		override protected function onShown(): void {
			var list: fairygui.GList = this.contentPane.getChild("n6").asList;
			list.removeChildrenToPool();
			
			for(var i: int = 0;i < 6;i++) {
				var item: fairygui.GButton = list.addItemFromPool().asButton;
				item.title = "" + i;
				item.icon = fairygui.UIPackage.getItemURL("Demo","r4");
			}
		}
	}
}