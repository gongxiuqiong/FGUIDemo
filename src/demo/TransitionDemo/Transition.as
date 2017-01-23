package demo.TransitionDemo
{
	import fairygui.GRoot;
	import fairygui.UIPackage;
	
	import laya.net.Loader;
	import laya.utils.Handler;
	import laya.webgl.WebGL;

	public class Transition
	{
		public function Transition()
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
				{ url: "res/transition/Transition@atlas0.png", type: Loader.IMAGE },
				{ url: "res/transition/Transition.fui", type: Loader.BUFFER},
				{ url: "res/Transition@lvxrs.mp3", type: Loader.SOUND  }
			], Handler.create(this, this.onLoaded));
		}
		
		private function onLoaded(): void
		{
			Laya.stage.addChild(GRoot.inst.displayObject);
			
			UIPackage.addPackage("res/transition/Transition");	
			
			new MainPanel();
		}
	}
}