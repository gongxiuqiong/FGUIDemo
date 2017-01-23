package demo.MainDemo
{
	import fairygui.Window;
	
	import laya.utils.Ease;
	import laya.utils.Handler;
	import laya.utils.Tween;
	
	public class WindowB extends Window
	{
		public function WindowB()
		{
			super();
		}
		
		override protected function onInit():void {        
			this.contentPane = fairygui.UIPackage.createObject("Basic", "WindowB").asCom;
			this.center();
			
			//弹出窗口的动效已中心为轴心
			this.setPivot(0.5, 0.5);
		}
		
		override protected function doShowAnimation():void
		{
			this.setScale(0.1, 0.1);
			Tween.to(this, { scaleX: 1,scaleY: 1 },300, Ease.quadOut, Handler.create(this, this.onShown));
		}
		
		override protected function doHideAnimation():void
		{
			Tween.to(this, { scaleX: 0.1,scaleY: 0.1 },300, Ease.quadOut, Handler.create(this, this.hideImmediately));
		}
		
		override protected function onShown():void
		{
			this.contentPane.getTransition("t1").play();	
		}
		
		override protected function onHide():void
		{
			this.contentPane.getTransition("t1").stop();
		}
	}
}