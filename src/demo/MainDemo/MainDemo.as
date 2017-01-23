package demo.MainDemo
{
	import fairygui.GRoot;
	import fairygui.UIConfig;
	import fairygui.UIPackage;
	
	import laya.net.Loader;
	import laya.utils.Handler;
	import laya.webgl.WebGL;

	public class MainDemo
	{
		public function MainDemo()
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
				{ url: "res/basic/Basic@atlas0.png", type: Loader.IMAGE },
				{ url: "res/basic/Basic.fui", type: Loader.BUFFER }
			], Handler.create(this, this.onLoaded));
		}
		private function onLoaded(): void
		{
			Laya.stage.addChild(GRoot.inst.displayObject);
			
			UIPackage.addPackage("res/basic/Basic");		
			fairygui.UIConfig.defaultFont = "宋体";
			fairygui.UIConfig.verticalScrollBar = UIPackage.getItemURL("Basic", "ScrollBar_VT");
			fairygui.UIConfig.horizontalScrollBar = UIPackage.getItemURL("Basic", "ScrollBar_HZ");
			fairygui.UIConfig.popupMenu = UIPackage.getItemURL("Basic", "PopupMenu");
			fairygui.UIConfig.buttonSound = UIPackage.getItemURL("Basic","click");
			
			new MainPanel();
		}
	}
}