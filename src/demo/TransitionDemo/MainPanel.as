package demo.TransitionDemo
{
	import fairygui.GComponent;
	import fairygui.GGroup;
	import fairygui.GRoot;
	import fairygui.Transition;
	import fairygui.UIPackage;
	
	import laya.utils.Ease;
	import laya.utils.Handler;
	import laya.utils.Tween;

	public class MainPanel
	{
		private var _view: GComponent;
		
		private var _btnGroup: GGroup;
		private var _g1: GComponent;
		private var _g2: GComponent;
		private var _g3: GComponent;
		private var _g4: GComponent;
		private var _g5: GComponent;
		
		private var _tweeObject: Object;
		private var _startValue: Number;
		private var _endValue: Number;
		
		public function MainPanel()
		{
			this._view = UIPackage.createObject("Transition","Main").asCom;
			this._view.setSize(GRoot.inst.width,GRoot.inst.height);
			GRoot.inst.addChild(this._view);
			
			this._tweeObject = { value: 0 };
			this._btnGroup = this._view.getChild("g0").asGroup;
			
			this._g1 = UIPackage.createObject("Transition","BOSS").asCom;
			this._g2 = UIPackage.createObject("Transition","BOSS_SKILL").asCom;
			this._g3 = UIPackage.createObject("Transition","TRAP").asCom;
			this._g4 = UIPackage.createObject("Transition","GoodHit").asCom;
			this._g5 = UIPackage.createObject("Transition","PowerUp").asCom;
			//play_num_now是在编辑器里设定的名称，这里表示播放到'play_num_now'这个位置时才开始播放数字变化效果
			this._g5.getTransition("t0").setHook("play_num_now",Handler.create(this, this.__playNum, null, false));
			
			this._view.getChild("btn0").onClick(this,function(): void { this.__play(this._g1); });
			this._view.getChild("btn1").onClick(this,function(): void { this.__play(this._g2); });
			this._view.getChild("btn2").onClick(this,function(): void { this.__play(this._g3); });
			this._view.getChild("btn3").onClick(this,this.__play4);
			this._view.getChild("btn4").onClick(this,this.__play5);
		}
		
		private function __play(target: GComponent): void {
			this._btnGroup.visible = false;
			GRoot.inst.addChild(target);
			var t: fairygui.Transition = target.getTransition("t0");
			t.play(Handler.create(this, function(): void {
				this._btnGroup.visible = true;
				GRoot.inst.removeChild(target);
			}));
		}
		
		private function __play4(): void {
			this._btnGroup.visible = false;
			this._g4.x = GRoot.inst.width - this._g4.width - 20;
			this._g4.y = 100;
			GRoot.inst.addChild(this._g4);
			var t: fairygui.Transition = this._g4.getTransition("t0");
			//播放3次
			t.play(Handler.create(this, function(): void {
				this._btnGroup.visible = true;
				GRoot.inst.removeChild(this._g4);
			}),3);
		}
		
		private function __play5(): void {
			this._btnGroup.visible = false;
			this._g5.x = 20;
			this._g5.y = GRoot.inst.height - this._g5.height - 100;
			GRoot.inst.addChild(this._g5);
			var t: fairygui.Transition = this._g5.getTransition("t0");
			this._startValue = 10000;
			var add: Number = Math.ceil(Math.random() * 2000 + 1000);
			this._endValue = this._startValue + add;
			this._g5.getChild("value").text = "" + this._startValue;
			this._g5.getChild("add_value").text = "+" + add;
			t.play(Handler.create(this, function(): void {
				this._btnGroup.visible = true;
				GRoot.inst.removeChild(this._g5);
			}));
		}
		
		private function __playNum(): void {
			//这里演示了一个数字变化的过程
			this._tweeObject.value = this._startValue;
			Tween.to(this._tweeObject, { value: this._endValue }, 300, Ease.linearNone).update
				= Handler.create(this,  function(): void {
					this._g5.getChild("value").text = "" + Math.floor(this._tweeObject.value);
				}, null, false);
		}
	}
}