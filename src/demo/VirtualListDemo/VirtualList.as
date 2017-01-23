package demo.VirtualListDemo
{	
	import fairygui.GRoot;
	import fairygui.UIObjectFactory;
	import fairygui.UIPackage;
	
	import laya.net.Loader;
	import laya.utils.Handler;
	import laya.webgl.WebGL;

	public class VirtualList
	{
		public function VirtualList()
		{
			Laya.init(1136, 640, WebGL);
			//设置适配模式
			Laya.stage.scaleMode = "showall";
			Laya.stage.alignH = "left";
			Laya.stage.alignV = "top";
			//设置横竖屏
			Laya.stage.screenMode = "horizontal";
			Laya.stage.bgColor = "#333333";
			Laya.loader.load([
				{ url: "res/virtualList/VirtualList@atlas0.png", type: Loader.IMAGE },
				{ url: "res/virtualList/VirtualList.fui", type: Loader.BUFFER}
			], Handler.create(this, this.onLoaded));
		}
		
		private function onLoaded(): void
		{
			Laya.stage.addChild(GRoot.inst.displayObject);
			
			UIPackage.addPackage("res/virtualList/VirtualList");
			UIObjectFactory.setPackageItemExtension(UIPackage.getItemURL("VirtualList","mailItem"),MailItem);	
			
			new MainPanel();
		}
	}
}