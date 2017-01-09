package 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	/**
	 * ...
	 * @author lenglang
	 */
	public class Main extends Sprite
	{
		private var _sprites:Array = [];//画线数组
		private var _spritePool:Array = [];//对象池
		private var _points:Array = [[new Point(100,100),new Point(500,100),new Point(500,500),new Point(100,500)]];//纸张初始点
		private var _newPoints:Array = [];
		private var _length:int = 20;//补助折线虚线单根长
		private var _dis:int = 10;//补助折线虚线间距
		private var _clickPoint:Point=new Point();//点击点
		private var _arrow:MovieClip;//补助方向箭头
		private var _movePoint:Point=new Point();//鼠标移动点
		private var _lastPoint:Point=new Point();//上一个点
		private var _symmetryLength:Number = 1000;
		private var _K:Number = 0;//斜率
		private var _b:Number = 0;//b值
		private var _angle:Number = 0;//角度
		private var _firstBoolean:Boolean = false;//离最近的点可对称
		private var _earlyPoint:Point = new Point();
		public function Main()
		{
			if (stage)
			{
				init();
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//预先创建sprite对象池
			for (var i:int = 0; i < 2000; i++)
			{
				var sprite:Sprite = new Sprite();
				addChild(sprite);
				_spritePool.push(sprite);
			}
			//初始纸张
			drawGraphics(_points[0], 0x000000, 0xffffff);
			//生成箭头
			//_arrow = new Arrow();
			//_arrow.x = stage.mouseX;
			//_arrow.y = stage.mouseY;
			//addChild(_arrow);
			//添加事件
			stage.addEventListener(MouseEvent.MOUSE_DOWN, stageMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, stageMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, stageMouseMove);
			this.addEventListener(Event.ENTER_FRAME, this.frameIng);
			stage.mouseChildren = false;
		}
		private function frameIng(e:Event):void
		{

		}
		//移动
		private function stageMouseMove(e:MouseEvent):void
		{
			//_arrow.x = stage.mouseX;
			//_arrow.y = stage.mouseY;
			_movePoint.x = stage.mouseX;
			_movePoint.y = stage.mouseY;
			if (getDistance(_movePoint, _lastPoint) < 0)
			{
				return;
			}
			_lastPoint.x = stage.mouseX;
			_lastPoint.y = stage.mouseY;
			if (e.buttonDown)
			{
				//清空线
				for (var j:int = 0; j < _sprites.length; j++)
				{
					_sprites[j].graphics.clear();
					_spritePool.push(_sprites[j]);
				}
				_sprites = [];
				_angle = getAngle(_clickPoint,_movePoint);
				//_arrow.rotation = _angle;
				if (_firstBoolean == false)
				{
					_earlyPoint = getEarlyPoint();
					_firstBoolean = true;
				}
				if (_angle == 90)
				{
					_angle = 90.001;
				}
				else if (_angle == 180)
				{
					_angle = 180.001;
				}
				else if (_angle == -180)
				{
					_angle = -180.001;
				}
				else if (_angle == 0)
				{
					
				}
				if (_angle == -90)
				{
					_angle = -90.001;
				}
				var radian = (_angle - 90) * Math.PI / 180;
				_K = Math.tan(radian);
				//之前是以最近的点最为参照
				_b = (_clickPoint.y + _movePoint.y) / 2 - (_K * (_movePoint.x + _clickPoint.x) / 2);
				//折线
				var p1:Point = new Point(_symmetryLength,_K * _symmetryLength + _b);
				var p2:Point = new Point( -  _symmetryLength, -  _K * _symmetryLength + _b);
				if (_angle == 0)
				{
					p1.x =(_clickPoint.x + _movePoint.x) / 2;
					p1.y = _symmetryLength;
					
					p2.x = (_clickPoint.x + _movePoint.x) / 2;
					p2.y = -_symmetryLength;
					
				}
				drawLine(p1, p2, 0x00CC00);
				//是可以映射
				_newPoints = [];
				for (var l:int = _points.length-1; l >=0; l--)
				{
					countDraw(_points[l]);
				}
				var color:int = 0x000000;
				for (var w:int = 0; w < _newPoints.length; w++)
				{
					if (w == 0)
					{
						color = 0x000000;
					}
					else
					{
						color = 0xff0000;
					}
					if (_newPoints.length == 1)
					{
						color = 0x000000;
					}
					this.setChildIndex(drawGraphics(_newPoints[w], color, 0xffffff),this.numChildren-1);
				}
			}
		}
		/**
		 * 计算画线
		 * @param	points
		 */
		private function countDraw(points:Array)
		{
			var symmetryPoints:Array = [];
			var lessPoints:Array = [];
			for (var i:int = 0; i < points.length; i++)
			{
				if (_angle == 0)
				{
					//右移
					if (_clickPoint.x < _movePoint.x&&points[i].x<(_clickPoint.x+_movePoint.x)/2)
					{
						
						symmetryPoints.push(getSymmetry(points[i]));
					}
					//左移
					else if (_clickPoint.x > _movePoint.x&&points[i].x>(_clickPoint.x+_movePoint.x)/2)
					{symmetryPoints.push(getSymmetry(points[i]));}
					else{lessPoints.push(points[i]);}
					continue;
				}

				if (_clickPoint.y < _movePoint.y)
				{
					//下移
					if (points[i].y > points[i].x * _K + _b)
					{
						lessPoints.push(points[i]);
					}
					else
					{
						//_firstBoolean = true;
						symmetryPoints.push(getSymmetry(points[i]));
					}
				}
				else
				{
					//上移
					if (points[i].y < points[i].x * _K + _b)
					{
						lessPoints.push(points[i]);
					}
					else
					{
						//_firstBoolean = true;
						symmetryPoints.push(getSymmetry(points[i]));
					}
				}
			}
			//是否有交点
			var focusPoints:Array = [];
			for (var n:int = 0; n < points.length; n++)
			{
				var focus:Point;
				if (n == points.length - 1)
				{
					focus = getFocus(points[n],points[0]);
				}
				else
				{
					focus = getFocus(points[n],points[n + 1]);
				}
				if (focus != null)
				{
					focusPoints.push(focus);
				}
			}
			
			//_newPoints = [];
			var arr1:Array = [];
			arr1 = arr1.concat(lessPoints);
			arr1 = arr1.concat(focusPoints);
			sortPoint(arr1);
			if (arr1.length != 0)
			{
			   _newPoints.unshift(arr1);
			}
			var arr2:Array = [];
			arr2 = arr2.concat(focusPoints);
			arr2 = arr2.concat(symmetryPoints);
			sortPoint(arr2);
			if  (arr2.length != 0)
			{
				_newPoints.push(arr2);
			}
		}
		private function stageMouseDown(e:MouseEvent):void
		{
			_firstBoolean = false;
			_movePoint = new Point(stage.mouseX,stage.mouseY);
			_lastPoint = new Point(stage.mouseX,stage.mouseY);
			_clickPoint = new Point(stage.mouseX,stage.mouseY);
		}
		private function stageMouseUp(e:MouseEvent):void
		{
			//_symmetry.graphics.clear();
			_points = [];
			_points = _points.concat(_newPoints);
		}
		/**
		 * 画图形
		 * @parampoints       点集
		 * @parambgColor      填充颜色
		 * @paramlineColor    线颜色
		 * @paramlineSize     线大小
		 */
		private function drawGraphics(points:Array, bgColor:int, lineColor:int,lineSize:int=2):Sprite
		{
			var sprite:Sprite = getSprite();
			sprite.graphics.lineStyle(lineSize, lineColor);
			sprite.graphics.beginFill(bgColor, 0.5);
			for (var i:int = 0; i < points.length; i++)
			{
				if (i == 0)
				{
					sprite.graphics.moveTo(points[i].x, points[i].y);
				}
				else
				{
					sprite.graphics.lineTo(points[i].x, points[i].y);
				}
			}
			return sprite;
		}
		/**
		 * 
		 * @paramsp         开始点
		 * @paramep         结束点
		 * @paramlineColor  线颜色
		 * @paramlineSize   线大小
		 */
		private function drawLine(sp:Point, ep:Point, lineColor:int, lineSize:int = 2)
		{
			var sprite:Sprite = getSprite();
			sprite.graphics.lineStyle(lineSize, lineColor);
			sprite.graphics.moveTo(sp.x, sp.y);
			sprite.graphics.lineTo(ep.x, ep.y);
		}
		/**
		 * 获取画线sprite
		 * @return
		 */
		private function getSprite():Sprite
		{
			if (_spritePool.length != 0)
			{
				var temp = _spritePool[0];
				_spritePool.splice(0, 1);
				_sprites.push(temp);
				return temp;
			}
			return null;
		}
		/**
		 * 获取对称点
		 */
		private function getSymmetry(p:Point):Point
		{
			var point:Point=new Point();
			point.x = (2 * p.y * _K - 2 * _b * _K + p.x - _K * _K * p.x) / (1 + _K * _K);
			point.y = p.y - (point.x - p.x) / _K;
			if (_angle == 0)
			{
				if (_clickPoint.x < _movePoint.x)
				{
					//右
					point.x =p.x + ((_movePoint.x + _clickPoint.x) / 2 - p.x) * 2;
				}
				else
				{
					//左
					point.x =p.x - (p.x-(_movePoint.x + _clickPoint.x) / 2) * 2;
				}
			}
			return point;
		}
		/**
		 * 获取两点之间的距离
		 * @paramp1
		 * @paramp2
		 */
		private function getDistance(p1:Point,p2:Point):Number
		{
			return Math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
		}
		/**
		 * 获取两点之间角度
		 * @paramp1
		 * @paramp2
		 */
		private function getAngle(p1:Point,p2:Point)
		{
			var vx = p2.x - p1.x;
			var vy = p2.y - p1.y;
			var hyp = Math.sqrt(Math.pow(vx,2) + Math.pow(vy,2));
			var rad=Math.acos(vx/hyp);
			var deg = 180/(Math.PI / rad);
			//得到了一个角度“rad”，不过是以弧度为单位的
			//把它转换成角度 
			if (vy<0)
			{
				deg=(-deg);
			}
			else if ((vy == 0) && (vx <0))
			{
				deg = 180;
			}
			return deg;
		}
		/**
		 * 点排序
		 * @parampoints
		 */
		private function sortPoint(points:Array)
		{
			//重心点
			var center:Point = new Point();
			center = getCenter(points);
			var boolean:Boolean = true;
			while (boolean)
			{
				boolean = false;
				for (var j:int = 0; j < points.length-1; j++)
				{
					if (getAngle(center, points[j]) > getAngle(center, points[j + 1]))
					{
						var temp = points[j];
						points[j] = points[j + 1];
						points[j + 1] = temp;
						boolean = true;
					}
				}
			}
		}

		/**
		 * @description 射线法判断点是否在多边形内部
		 * @param {Object} p 待判断的点，格式：{ x: X 坐标, y: Y 坐标 }
		 * @param {Array} poly 多边形顶点，数组成员的格式同 p
		 * @return {String} 点 p 和多边形 poly 的几何关系
		 */
		private function rayCasting(p, poly)
		{
			var px = p.x,
			      py = p.y,
			      flag = false;

			for (var i = 0, l = poly.length, j = l - 1; i < l; j = i, i++)
			{
				var sx = poly[i].x,
				        sy = poly[i].y,
				        tx = poly[j].x,
				        ty = poly[j].y;

				// 点与多边形顶点重合
				if ((sx === px && sy === py) || (tx === px && ty === py))
				{
					return 'on';
				}

				// 判断线段两端点是否在射线两侧
				if ((sy < py && ty >= py) || (sy >= py && ty < py))
				{
					// 线段上与射线 Y 坐标相同的点的 X 坐标
					var x = sx + (py - sy) * (tx - sx) / (ty - sy);

					// 点在多边形的边上
					if (x === px)
					{
						return 'on';
					}

					// 射线穿过多边形的边界
					if (x > px)
					{
						flag = ! flag;
					}
				}
			}
			// 射线穿过多边形边界的次数为奇数时点在多边形内
			return flag ? 'in' : 'out';
		}

		/**
		 * 获取重心
		 * @return
		 */
		private function getCenter(points:Array):Point
		{
			var center:Point = new Point();
			for (var i:int = 0; i < points.length; i++)
			{
				center.x +=  points[i].x;
				center.y +=  points[i].y;
			}
			center.x = center.x / points.length;
			center.y = center.y / points.length;
			return center;
		}
		/**
		 * 获取折线与线段的交点
		 * @paramp1
		 * @paramp2
		 * @return
		 */
		private function getFocus(p1:Point,p2:Point):Point
		{
			var angle:Number = getAngle(p1,p2);
			var radian = angle * Math.PI / 180;
			var x1:Number;
			var x2:Number;
			var y1:Number;
			var y2:Number;
			var point:Point = new Point();
			var k2 = Math.tan(radian);
			var b2 = p2.y - (k2 * p2.x);


			//trace(k2,"k",p1,p2);
			if (Math.abs(angle) == 90)
			{
				
				y1 = y2 = _b;
				x1 = x2 = p1.x;
				point.x = x1;
				point.y = _K * x1 + _b;
			}
			else if (_angle == 0)
			{
				y1 = y2=p1.y;
				x1 = x2 = (_clickPoint.x + _movePoint.x) / 2;
				point.x = x1;
				point.y = y1;
			}
			else
			{
				trace(p1,p2);
				x1 = x2 = point.x = (_b - b2) / (k2 - _K);
				y1 = _K * point.x + _b;
				y2 = k2 * point.x + b2;
				point.y = y1;
			}
			//trace(point);
			if (Math.round(x1) == Math.round(x2) && Math.round(y1) == Math.round(y2) && Math.round(point.x) >= Math.round(Math.min(p1.x,p2.x)) && Math.round(point.x) <= Math.round(Math.max(p1.x,p2.x)) && Math.round(point.y) <= Math.round(Math.max(p1.y,p2.y)) && Math.round(point.y) >= Math.round(Math.min(p1.y,p2.y)))
			{
				return point;
			}
			return null;
		}
		/**
		 * 与鼠标最近的点
		 */
		private function getEarlyPoint():Point
		{
			var point:Point = new Point();
			point = _points[0][0];
			var dis:Number = getDistance(new Point(stage.mouseX,stage.mouseY),point);
			for (var i:int = 0; i < _points.length; i++)
			{
				for (var j:int = 1; j < _points[i].length; j++)
				{
					var tempDis:Number = getDistance(new Point(stage.mouseX,stage.mouseY),_points[i][j]);
					if (dis > tempDis)
					{
						dis = tempDis;
						point = _points[i][j];
					}
				}
			}
			return point;
		}
	}
}