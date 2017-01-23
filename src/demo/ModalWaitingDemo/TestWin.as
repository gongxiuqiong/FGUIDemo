package demo.ModalWaitingDemo
{
	import fairygui.UIPackage;
	import fairygui.Window;
	
	public class TestWin extends Window
	{
		public function TestWin()
		{
			super();
		}
		
		override protected function onInit(): void {
			this.contentPane = fairygui.UIPackage.createObject("ModalWaiting","TestWin").asCom;
			this.contentPane.getChild("n1").onClick(this, this.onClickStart);
		}
		
		private function onClickStart(): void {
			//这里模拟一个要锁住当前窗口的过程，在锁定过程中，窗口仍然是可以移动和关闭的
			this.showModalWait();
			Laya.timer.once(3000,this,function(): void { this.closeModalWait(); });
		}
	}
}