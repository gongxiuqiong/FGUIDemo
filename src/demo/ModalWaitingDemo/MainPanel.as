package demo.ModalWaitingDemo
{
	import fairygui.GComponent;
	import fairygui.GRoot;

	public class MainPanel
	{
		private var _view: GComponent;
		private var _testWin: TestWin;
		
		public function MainPanel()
		{
			this._view = fairygui.UIPackage.createObject("ModalWaiting","Main").asCom;
			this._view.setSize(fairygui.GRoot.inst.width,fairygui.GRoot.inst.height);
			GRoot.inst.addChild(this._view);
			
			this._testWin = new TestWin();
			this._view.getChild("n0").onClick(this, function(): void { this._testWin.show(); });
			
			//这里模拟一个要锁住全屏的等待过程
			GRoot.inst.showModalWait();
			Laya.timer.once(3000,this, function(): void {
				GRoot.inst.closeModalWait();
			});
		}
	}
}