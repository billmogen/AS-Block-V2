﻿/*
* AS-Block-v2.0 is Based on Scratch 2.0
* www.cfunworld.com
* QQ群:366029023
*/

/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// Scratch.as
// John Maloney, September 2009
//
// This is the top-level application.

package {
import com.quetwo.Arduino.ArduinoConnector;
import com.quetwo.Arduino.ArduinoConnectorEvent;

import flash.desktop.NativeApplication;
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageScaleMode;
import flash.errors.IllegalOperationError;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.InvokeEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.events.TimerEvent;
import flash.events.UncaughtErrorEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.FileReference;
import flash.net.FileReferenceList;
import flash.net.LocalConnection;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.system.Capabilities;
import flash.system.System;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.utils.getTimer;

import blocks.Block;

import extensions.ExtensionManager;

import interpreter.Interpreter;

import primitives.CFunPrims;

import render3d.DisplayObjectContainerIn3D;

import scratch.BlockMenus;
import scratch.PaletteBuilder;
import scratch.ScratchCostume;
import scratch.ScratchObj;
import scratch.ScratchRuntime;
import scratch.ScratchSound;
import scratch.ScratchSprite;
import scratch.ScratchStage;

import translation.Translator;

import ui.BlockPalette;
import ui.CameraDialog;
import ui.LoadProgress;
import ui.media.MediaInfo;
import ui.media.MediaLibrary;
import ui.media.MediaPane;
import ui.parts.ImagesPart;
import ui.parts.LibraryPart;
import ui.parts.ScriptsPart;
import ui.parts.SoundsPart;
import ui.parts.StagePart;
import ui.parts.TabsPart;
import ui.parts.TopBarPart;

import uiwidgets.BlockColorEditor;
import uiwidgets.CursorTool;
import uiwidgets.DialogBox;
import uiwidgets.IconButton;
import uiwidgets.Menu;
import uiwidgets.ScriptsPane;

import util.GestureHandler;
import util.ProjectIO;
import util.Server;
import util.Transition;

import watchers.ListWatcher;

//import primitives.*;//输出testnum用_wh


public class Scratch extends Sprite {
	// Version
	public static const versionString:String = 'v2.0';//版本号_wh
	public static var app:Scratch; // static reference to the app, used for debugging

	// Display modes
	public var editMode:Boolean; // true when project editor showing, false when only the player is showing//编辑框标志
	public var isOffline:Boolean; // true when running as an offline (i.e. stand-alone) app//离线版本标志
	public var isSmallPlayer:Boolean; // true when displaying as a scaled-down player (e.g. in search results)
	public var stageIsContracted:Boolean; // true when the stage is half size to give more space on small screens
	public var isIn3D:Boolean;
	public var render3D:IRenderIn3D;
	public var isArmCPU:Boolean;
	public var jsEnabled:Boolean = false; // true when the SWF can talk to the webpage//

	// Runtime
	public var runtime:ScratchRuntime;
	public var interp:Interpreter;
	public var extensionManager:ExtensionManager;
	public var server:Server;
	public var gh:GestureHandler;
	public var projectID:String = '';
	public var projectOwner:String = '';
	public var projectIsPrivate:Boolean;
	public var oldWebsiteURL:String = '';
	public var loadInProgress:Boolean;
	public var debugOps:Boolean = false;
	public var debugOpCmd:String = '';

	protected var autostart:Boolean;
	private var viewedObject:ScratchObj;
	private var lastTab:String = 'scripts';
	protected var wasEdited:Boolean; // true if the project was edited and autosaved
	private var _usesUserNameBlock:Boolean = false;
	protected var languageChanged:Boolean; // set when language changed

	// UI Elements
	public var playerBG:Shape;
	public var palette:BlockPalette;
	public var scriptsPane:ScriptsPane;
	public var stagePane:ScratchStage;
	public var mediaLibrary:MediaLibrary;
	public var lp:LoadProgress;
	public var cameraDialog:CameraDialog;

	// UI Parts
	public var libraryPart:LibraryPart;
	protected var topBarPart:TopBarPart;
	protected var stagePart:StagePart;
	private var tabsPart:TabsPart;
	protected var scriptsPart:ScriptsPart;
	public var imagesPart:ImagesPart;
	public var soundsPart:SoundsPart;
	public const tipsBarClosedWidth:int = 17;
	
	public var arduino:ArduinoConnector;
	public var comTrue:Boolean = false;
	public var comIDTrue:String;
	public var comDataArray:Array = new Array();
	public var comDataArrayOld:Array = new Array();
	public var comRevFlag:Boolean = false;
	public var comCOMing:Boolean = false;
	
	public var process:NativeProcess = new NativeProcess();
	public var process2:NativeProcess = new NativeProcess();
	public var nativePSInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();//_wh
	public var file0:File;
	public var cmdBackNum:int = 0;
//	public var waitText:TextField=new TextField();
//	public var _lableAttribute:TextFormat;
	public var connectCir:Shape = new Shape();
	public var delay1sTimer:Timer;
	
	public var ArduinoFlag:Boolean = false;
	public var ArduinoLoopFlag:Boolean = false;
	public var ArduinoReadFlag:Boolean = false;
	public var ArduinoReadStr:Array = new Array;
	public var ArduinoValueFlag:Boolean = false;
	public var ArduinoValueStr:String = new String;
	public var ArduinoMathFlag:Boolean = false;
	public var ArduinoMathStr:Array = new Array;
	public var ArduinoMathNum:Number = 0;
	public var ArduinoFile:File;//_wh
	public var ArduinoFs:FileStream;//_wh
	public var ArduinoFileB:File;//_wh
	public var ArduinoFsB:FileStream;//_wh
	public var ArduinoPinFile:File;//pinmode_wh
	public var ArduinoPinFs:FileStream;//_wh
	public var ArduinoDoFile:File;//_wh
	public var ArduinoDoFs:FileStream;//_wh
	public var ArduinoHeadFile:File;//include和变量定义_wh
	public var ArduinoHeadFs:FileStream;//_wh
	public var ArduinoLoopFile:File;//循环_wh
	public var ArduinoLoopFs:FileStream;//_wh
	public var ArduinoPin:Array = new Array;
	public var ArduinoBlock:Array = new Array;
	public var ArduinoBracketN:Number = 0;
	public var ArduinoBracketXF:Array = new Array;
	public var ArduinoElseYi:Number = 0;//_wh
	//public var ArduinoIEN:Number = 0;
	public var ArduinoFirmN:int = 0;
	public var ArduinoCOMRate:int = 115200;//串口波特率_wh
	
	public var closeOK:Boolean = false;
	public var closeWait:Boolean = false;
	public var ArduinoWarnFlag:Boolean = false;
	public var ArduinoRPFlag:Boolean = false;
	public var ArduinoRPNum:Number = 0;
	public var openNum:Boolean = false;//_wh
	
	public var ArduinoUs:Boolean = false;//超声波_wh
	public var ArduinoSeg:Boolean = false;//数码管_wh
	public var ArduinoRGB:Boolean = false;//三色灯_wh
	public var ArduinoBuz:Boolean = false;//无源蜂鸣器_wh
	public var ArduinoCap:Boolean = false;//电容值_wh
	public var ArduinoDCM:Boolean = false;//方向电机_wh
	public var ArduinoSer:Boolean = false;//舵机_wh
	public var ArduinoIR:Boolean = false;//红外遥控_wh
	public var ArduinoTem:Boolean = false;//温度_wh
	public var ArduinoAvo:Boolean = false;//避障_wh
	public var ArduinoTra:Boolean = false;//循迹_wh
	
	//public var ArduinoNAN:Boolean = false;//无效数据标志_wh
	
	public var timeDelayAll:Number = 0;
	public var timeStart:Number = 0;
	public var tFlag:Boolean = false;
	
	public var blueFlag:Boolean = false;//是否蓝牙通信模式_wh
	public var readCDFlag:Boolean = false;
	
	public var CKkey1:Number = 0;//CK板变量值_wh
	public var CKkey2:Number = 0;//CK板变量值_wh
	public var CKsound:Number = 0;//CK板变量值_wh
	public var CKslide:Number = 0;//CK板变量值_wh
	public var CKlight:Number = 0;//CK板变量值_wh
	public var CKjoyx:Number = 0;//CK板变量值_wh
	public var CKjoyy:Number = 0;//CK板变量值_wh
	
	public var UpDialog:DialogBox = new DialogBox();//_wh
	public var ArduinoFirmFlag:Number = 0;
	public var UDFlag:Boolean = false;
	
	public var DriveFlag:Number = 0;
	public var OS:String = new String;
	
	public var test:Number = 0;
	
	public var showCOMFlag:Boolean = false;
	
	public var debugwh:Boolean = true;
	
	public function Scratch() {
		if(debugwh == false)
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvokeEvent); 
		
		loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		app = this;

		// This one must finish before most other queries can start, so do it separately
		determineJSAccess();//initialize()函数_wh
		
	}
	
	//应用事件处理_wh
	public function onInvokeEvent(invocation:InvokeEvent):void {
		var sb2str:String = invocation.arguments[0];
		if(sb2str.indexOf(".sb2") != -1)
		{
			if(openNum)
				return;
			var reg:RegExp = /\\/g;
			var strsb:String = sb2str.replace(reg,"/");
			runtime.initProjectFile(strsb);
		}
		if(sb2str.indexOf(".sb") != -1)
		{
			if(openNum)
				return;
			var reg:RegExp = /\\/g;
			var strsb:String = sb2str.replace(reg,"/");
			runtime.initProjectFile(strsb);
		}
	} 
	
	public var dllOk:Number = 10;
	protected function initialize():void {
		var OS32:Boolean = Capabilities.supports32BitProcesses;
		var OS64:Boolean = Capabilities.supports64BitProcesses;
		OS = Capabilities.os;
		var OS32str:String = "C:/Windows/System32/";
		var OS64str:String = "C:/Windows/SysWOW64/";
		var file2:File;
		var file3:File;
		try
		{
			file3= new File(File.applicationDirectory.resolvePath("avrtool/pthreadVC2.dll").nativePath);//_wh
			if(OS64)
				file2= new File(File.applicationDirectory.resolvePath(OS64str+"pthreadVC2.dll").nativePath);//_wh
			else
				file2= new File(File.applicationDirectory.resolvePath(OS32str+"pthreadVC2.dll").nativePath);//_wh
			if(file2.exists)
			{
				dllOk ++;
				file3.copyTo(file2,true);
			}
			else
			{
				file3.copyTo(file2,true);
				dllOk ++;
			}
		}
		catch(Error)
		{
			;
		}
		try
		{
			file3= new File(File.applicationDirectory.resolvePath("avrtool/msvcr100d.dll").nativePath);//_wh
			if(OS64)
				file2= new File(File.applicationDirectory.resolvePath(OS64str+"msvcr100d.dll").nativePath);//_wh
			else
				file2= new File(File.applicationDirectory.resolvePath(OS32str+"msvcr100d.dll").nativePath);//_wh
			if(file2.exists)
			{
				dllOk ++;
				file3.copyTo(file2,true);
			}
			else
			{
				file3.copyTo(file2,true);
				dllOk ++;
			}
		}
		catch(Error)
		{
			;
		}
//		var file1:File;
//		//*******************************************注意：每个版本需要修改（包括相应文件）*****************************************//
//		file1= new File(File.userDirectory.resolvePath("AS-Block/arduinos/flag_v1.7.4.txt").nativePath);//在相应目录下寻找或建立dll.txt_wh
//		//*******************************************注意：每个版本需要修改（包括相应文件）****************************************//
//		var fs:FileStream = new FileStream();
//		try
//		{
//			fs.open(file1,FileMode.READ);
//			fs.position = 0;
//			var i:int = fs.readByte();
//			fs.close();
//		}
//		catch(Error)
//		{
//			i = 0;
//		}
//		if(i != 49)
//		{
//			//DialogBox.warnconfirm(Translator.map(OS),Translator.map("please wait a moment"), null, app.stage);//软件界面中部显示提示框_whFirst start
//			file3= new File(File.applicationDirectory.resolvePath("arduinos").nativePath);//_wh
//			file2= new File(File.userDirectory.resolvePath("AS-Block/arduinos").nativePath);//_wh
//			file3.copyTo(file2,true);
//			file3= new File(File.applicationDirectory.resolvePath("ArduinoBuilder").nativePath);//_wh
//			file2= new File(File.userDirectory.resolvePath("AS-Block/ArduinoBuilder").nativePath);//_wh
//			file3.copyTo(file2,true);
//			fs.open(file1,FileMode.WRITE);
//			fs.position = 0;
//			fs.writeByte(49);
//			fs.close();
//		}
		
		app.ArduinoHeadFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/head.txt").nativePath);
		app.ArduinoHeadFs = new FileStream();
		app.ArduinoPinFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/pin.txt").nativePath);
		app.ArduinoPinFs = new FileStream();
		app.ArduinoDoFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/do.txt").nativePath);
		app.ArduinoDoFs = new FileStream();
		app.ArduinoLoopFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/loop.txt").nativePath);
		app.ArduinoLoopFs = new FileStream();
		app.ArduinoFile= new File(File.userDirectory.resolvePath("AS-Block/arduinos/arduinos.ino").nativePath);
		app.ArduinoFs = new FileStream();
		app.ArduinoFileB= new File(File.userDirectory.resolvePath("AS-Block/ArduinoBuilder/arduinos.ino").nativePath);
		app.ArduinoFsB = new FileStream();
		
		
		isOffline = loaderInfo.url.indexOf('http:') == -1;
		checkFlashVersion();//Flash版本处理函数？_wh
		initServer();

		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.frameRate = 30;

		Block.setFonts(10, 9, true, 0);
		Block.MenuHandlerFunction = BlockMenus.BlockMenuHandler;
		CursorTool.init(this);//光标_wh
		app = this;

		stagePane = new ScratchStage();
		gh = new GestureHandler(this, (loaderInfo.parameters['inIE'] == 'true'));
		initInterpreter();
		initRuntime();//ScratchRuntime() ?_wh
		initExtensionManager();
		Translator.initializeLanguageList();

		playerBG = new Shape(); // create, but don't add
		
		addParts();
		libraryPart.initSprite(0);
		
		server.getSelectedLang(Translator.setLanguageValue);
		

		stage.addEventListener(MouseEvent.MOUSE_DOWN, gh.mouseDown);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, gh.mouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, gh.mouseUp);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, gh.mouseWheel);
		stage.addEventListener('rightClick', gh.rightMouseClick);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, runtime.keyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, runtime.keyUp);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown); // to handle escape key
		stage.addEventListener(Event.ENTER_FRAME, step);
		stage.addEventListener(Event.RESIZE, onResize);
		
		stage.nativeWindow.addEventListener(Event.CLOSING,closingHandler);

		setEditMode(startInEditMode());

		// install project before calling fixLayout()
		if (editMode) runtime.installNewProject();
		else runtime.installEmptyProject();

		fixLayout();
		//Analyze.collectAssets(0, 119110);
		//Analyze.checkProjects(56086, 64220);
		//Analyze.countMissingAssets();
		
		
		arduino = new ArduinoConnector();
		
		CFunConCir(0);
		
		delay1sTimer = new Timer(1000, 75);
		delay1sTimer.addEventListener(TimerEvent.TIMER, onTick); 
		delay1sTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
		
		ArduinoBlock[CFunPrims.ID_ReadAFloat] = new Array();
		ArduinoBlock[CFunPrims.ID_ReadPFloat] = new Array();
		ArduinoBlock[CFunPrims.ID_SetSG] = new Array();
		ArduinoBlock[CFunPrims.ID_SetDM] = new Array();
		ArduinoBlock[CFunPrims.ID_SetNUM] = new Array();
		ArduinoBlock[CFunPrims.ID_SetMUS] = new Array();
	}
	
	public function CFunDelayms(t:Number):void
	{
		timeStart = getTimer();
		timeDelayAll = t;
		tFlag = true;
		//test = 0;
	}
	
	public function CFunConCir(b:Number):void
	{
		if(b == 1)
		{
			connectCir.graphics.beginFill(0x80ff00);
			connectCir.graphics.drawCircle(350,15,8);
			connectCir.graphics.drawCircle(370,15,8);
			connectCir.graphics.drawCircle(390,15,8);
			connectCir.graphics.endFill();
			addChild(connectCir);
		}
		else
		{
			if(b == 0)
			{
				connectCir.graphics.beginFill(0xff8060);
				connectCir.graphics.drawCircle(350,15,8);
				connectCir.graphics.drawCircle(370,15,8);
				connectCir.graphics.drawCircle(390,15,8);
				connectCir.graphics.endFill();
				addChild(connectCir);
			}
			else
			{
//				connectCir.graphics.beginFill(0xE0E000);
//				connectCir.graphics.drawCircle(350,15,8);
//				connectCir.graphics.drawCircle(370,15,8);
//				connectCir.graphics.drawCircle(390,15,8);
//				connectCir.graphics.endFill();
//				addChild(connectCir);
			}
		}
	}
	
	protected function closingHandler(e:Event):void
	{
		var winClosingEvent:Event; 
		winClosingEvent = new Event(Event.CLOSING,false,true); 
		NativeApplication.nativeApplication.dispatchEvent(winClosingEvent); 
		e.preventDefault();
		
		DialogBox.saveconfirm(Translator.map("Save project?"), app.stage, savePro, nosavePro);
	}
	
	//_wh
	protected function savePro():void
	{
		exportProjectToFile();
		closeWait = true;
	}
	
	//_wh
	protected function nosavePro():void
	{
		closeOK = true;
	}
	
	protected function initTopBarPart():void {
		topBarPart = new TopBarPart(this);
	}

	protected function initInterpreter():void {
		interp = new Interpreter(this);
	}

	protected function initRuntime():void {
		runtime = new ScratchRuntime(this, interp);
	}

	protected function initExtensionManager():void {
		extensionManager = new ExtensionManager(this);
	}

	protected function initServer():void {
		server = new Server();
	}

	protected function setupExternalInterface(oldWebsitePlayer:Boolean):void {
		if (!jsEnabled) return;

		addExternalCallback('ASloadExtension', extensionManager.loadRawExtension);
		addExternalCallback('ASextensionCallDone', extensionManager.callCompleted);
		addExternalCallback('ASextensionReporterDone', extensionManager.reporterCompleted);
	}

	public function showTip(tipName:String):void {
		switch(tipName)
		{
			default:break;
		}
	}
	public function closeTips():void {}
	public function reopenTips():void {}
	public function tipsWidth():int { return 0; }

	protected function startInEditMode():Boolean {
		return isOffline;
	}

	public function getMediaLibrary(type:String, whenDone:Function):MediaLibrary {
		return new MediaLibrary(this, type, whenDone);
	}

	public function getMediaPane(app:Scratch, type:String):MediaPane {
		return new MediaPane(app, type);
	}

	public function getScratchStage():ScratchStage {
		return new ScratchStage();
	}

	public function getPaletteBuilder():PaletteBuilder {
		return new PaletteBuilder(this);
	}

	private function uncaughtErrorHandler(event:UncaughtErrorEvent):void
	{
		if (event.error is Error)
		{
			var error:Error = event.error as Error;
			logException(error);
		}
		else if (event.error is ErrorEvent)
		{
			var errorEvent:ErrorEvent = event.error as ErrorEvent;
			logMessage(errorEvent.toString());
		}
	}

	public function log(s:String):void {
		trace(s);
	}

	public function logException(e:Error):void {}
	public function logMessage(msg:String, extra_data:Object=null):void {}
	public function loadProjectFailed():void {}

	protected function checkFlashVersion():void {
		/*SCRATCH::allow3d _wh*/ {
			if (Capabilities.playerType != "Desktop" || Capabilities.version.indexOf('IOS') === 0) {
				var versionString:String = Capabilities.version.substr(Capabilities.version.indexOf(' ') + 1);
				var versionParts:Array = versionString.split(',');
				var majorVersion:int = parseInt(versionParts[0]);
				var minorVersion:int = parseInt(versionParts[1]);
				if ((majorVersion > 11 || (majorVersion == 11 && minorVersion >= 7)) && !isArmCPU && Capabilities.cpuArchitecture == 'x86') {
					render3D = (new DisplayObjectContainerIn3D() as IRenderIn3D);
					render3D.setStatusCallback(handleRenderCallback);
					return;
				}
			}
		}

		render3D = null;
	}

	/*SCRATCH::allow3d _wh*/
	protected function handleRenderCallback(enabled:Boolean):void {
		if(!enabled) {
			go2D();
			render3D = null;
		}
		else {
			for(var i:int=0; i<stagePane.numChildren; ++i) {
				var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
				if(spr) {
					spr.clearCachedBitmap();
					spr.updateCostume();
					spr.applyFilters();
				}
			}
			stagePane.clearCachedBitmap();
			stagePane.updateCostume();
			stagePane.applyFilters();
		}
	}

	public function clearCachedBitmaps():void {
		for(var i:int=0; i<stagePane.numChildren; ++i) {
			var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
			if(spr) spr.clearCachedBitmap();
		}
		stagePane.clearCachedBitmap();

		// unsupported technique that seems to force garbage collection
		try {
			new LocalConnection().connect('foo');
			new LocalConnection().connect('foo');
		} catch (e:Error) {}
	}

	/*SCRATCH::allow3d _wh*/
	public function go3D():void {
		if(!render3D || isIn3D) return;

		var i:int = stagePart.getChildIndex(stagePane);
		stagePart.removeChild(stagePane);
		render3D.setStage(stagePane, stagePane.penLayer);
		stagePart.addChildAt(stagePane, i);
		isIn3D = true;
	}

	/*SCRATCH::allow3d _wh*/
	public function go2D():void {
		if(!render3D || !isIn3D) return;

		var i:int = stagePart.getChildIndex(stagePane);
		stagePart.removeChild(stagePane);
		render3D.setStage(null, null);
		stagePart.addChildAt(stagePane, i);
		isIn3D = false;
		for(i=0; i<stagePane.numChildren; ++i) {
			var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
			if(spr) {
				spr.clearCachedBitmap();
				spr.updateCostume();
				spr.applyFilters();
			}
		}
		stagePane.clearCachedBitmap();
		stagePane.updateCostume();
		stagePane.applyFilters();
	}

	protected function determineJSAccess():void {
		// After checking for JS access, call initialize().
		initialize();
	}

	private var debugRect:Shape;
	public function showDebugRect(r:Rectangle):void {
		// Used during debugging...
		var p:Point = stagePane.localToGlobal(new Point(0, 0));
		if (!debugRect) debugRect = new Shape();
		var g:Graphics = debugRect.graphics;
		g.clear();
		if (r) {
			g.lineStyle(2, 0xFFFF00);
			g.drawRect(p.x + r.x, p.y + r.y, r.width, r.height);
			addChild(debugRect);
		}
	}

	public function strings():Array {
		return [
			'a copy of the project file on your computer.',
			'Project not saved!', 'Save now', 'Not saved; project did not load.',
			'Save project?', 'Don\'t save',
			'Save now', 'Saved',
			'Revert', 'Undo Revert', 'Reverting...',
			'Throw away all changes since opening this project?',
		];
	}

	public function viewedObj():ScratchObj { return viewedObject; }
	public function stageObj():ScratchStage { return stagePane; }
	public function projectName():String { return stagePart.projectName(); }
	public function highlightSprites(sprites:Array):void { libraryPart.highlight(sprites); }
	public function refreshImageTab(fromEditor:Boolean):void { imagesPart.refresh(fromEditor); }
	public function refreshSoundTab():void { soundsPart.refresh(); }
	public function selectCostume():void { imagesPart.selectCostume(); }
	public function selectSound(snd:ScratchSound):void { soundsPart.selectSound(snd); }
	public function clearTool():void { CursorTool.setTool(null); topBarPart.clearToolButtons(); }
	public function tabsRight():int { return tabsPart.x + tabsPart.w; }
	public function enableEditorTools(flag:Boolean):void { imagesPart.editor.enableTools(flag); }

	public function get usesUserNameBlock():Boolean {
		return _usesUserNameBlock;
	}

	public function set usesUserNameBlock(value:Boolean):void {
		_usesUserNameBlock = value;
		stagePart.refresh();
	}

	public function updatePalette(clearCaches:Boolean = true):void {
		// Note: updatePalette() is called after changing variable, list, or procedure
		// definitions, so this is a convenient place to clear the interpreter's caches.
		if (isShowing(scriptsPart)) scriptsPart.updatePalette();
		if (clearCaches) runtime.clearAllCaches();
	}

	public function setProjectName(s:String):void {
		if (s.slice(-3) == '.sb') s = s.slice(0, -3);
		if (s.slice(-4) == '.sb2') s = s.slice(0, -4);
		stagePart.setProjectName(s);
	}

	protected var wasEditing:Boolean;
	public function setPresentationMode(enterPresentation:Boolean):void {
		if (enterPresentation) {
			wasEditing = editMode;
			if (wasEditing) {
				setEditMode(false);
				if(jsEnabled) externalCall('tip_bar_api.hide');
			}
		} else {
			if (wasEditing) {
				setEditMode(true);
				if(jsEnabled) externalCall('tip_bar_api.show');
			}
		}
		if (isOffline) {
			stage.displayState = enterPresentation ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
		}
		for each (var o:ScratchObj in stagePane.allObjects()) o.applyFilters();

		if (lp) fixLoadProgressLayout();
		stagePane.updateCostume();
		/*SCRATCH::allow3d _wh*/ { if(isIn3D) render3D.onStageResize(); }
	}

	private function keyDown(evt:KeyboardEvent):void {
		// Escape exists presentation mode.
		if ((evt.charCode == 27) && stagePart.isInPresentationMode()) {
			setPresentationMode(false);
			stagePart.exitPresentationMode();
		}
		// Handle enter key
//		else if(evt.keyCode == 13 && !stage.focus) {
//			stagePart.playButtonPressed(null);
//			evt.preventDefault();
//			evt.stopImmediatePropagation();
//		}
		// Handle ctrl-m and toggle 2d/3d mode
		else if(evt.ctrlKey && evt.charCode == 109) {
			/*SCRATCH::allow3d _wh*/ { isIn3D ? go2D() : go3D(); }
			evt.preventDefault();
			evt.stopImmediatePropagation();
		}
	}

	private function setSmallStageMode(flag:Boolean):void {
		stageIsContracted = flag;
		stagePart.refresh();
		fixLayout();
		libraryPart.refresh();
		tabsPart.refresh();
		stagePane.applyFilters();
		stagePane.updateCostume();
	}

	public function projectLoaded():void {
		removeLoadProgressBox();
		System.gc();
		if (autostart) runtime.startGreenFlags(true);
		saveNeeded = false;

		// translate the blocks of the newly loaded project
		for each (var o:ScratchObj in stagePane.allObjects()) {
			o.updateScriptsAfterTranslation();
		}
	}

	protected function step(e:Event):void {
		// Step the runtime system and all UI components.
		gh.step();
		runtime.stepRuntime();
		Transition.step(null);
		stagePart.step();
		libraryPart.step();
		scriptsPart.step();
		imagesPart.step();
		
		if(closeOK == true)
		{
			arduino.dispose();
			stage.nativeWindow.close();
		}
		if(dllOk < 12)
			dllOk --;
		if(dllOk == 5)
		{
			dllOk = 12;
			DialogBox.warnconfirm(OS + " User","please open with administrator privileges", null, app.stage);
		}
	}

	public function updateSpriteLibrary(sortByIndex:Boolean = false):void { libraryPart.refresh() }
	public function threadStarted():void { stagePart.threadStarted() }

	public function selectSprite(obj:ScratchObj):void {
		if (isShowing(imagesPart)) imagesPart.editor.shutdown();
		if (isShowing(soundsPart)) soundsPart.editor.shutdown();
		viewedObject = obj;
		libraryPart.refresh();
		tabsPart.refresh();
		if (isShowing(imagesPart)) {
			imagesPart.refresh();
		}
		if (isShowing(soundsPart)) {
			soundsPart.currentIndex = 0;
			soundsPart.refresh();
		}
		if (isShowing(scriptsPart)) {
			scriptsPart.updatePalette();
			scriptsPane.viewScriptsFor(obj);
			scriptsPart.updateSpriteWatermark();
		}
	}

	public function setTab(tabName:String):void {
		if (isShowing(imagesPart)) imagesPart.editor.shutdown();
		if (isShowing(soundsPart)) soundsPart.editor.shutdown();
		hide(scriptsPart);
		hide(imagesPart);
		hide(soundsPart);
		if (!editMode) return;
		if (tabName == 'images') {
			show(imagesPart);
			imagesPart.refresh();
		} else if (tabName == 'sounds') {
			soundsPart.refresh();
			show(soundsPart);
		} else if (tabName && (tabName.length > 0)) {
			tabName = 'scripts';
			scriptsPart.updatePalette();
			scriptsPane.viewScriptsFor(viewedObject);
			scriptsPart.updateSpriteWatermark();
			show(scriptsPart);
		}
		show(tabsPart);
		show(stagePart); // put stage in front
		tabsPart.selectTab(tabName);
		lastTab = tabName;
		if (saveNeeded) setSaveNeeded(true); // save project when switching tabs, if needed (but NOT while loading!)
	}

	public function installStage(newStage:ScratchStage):void {
		var showGreenflagOverlay:Boolean = shouldShowGreenFlag();
		stagePart.installStage(newStage, showGreenflagOverlay);
		selectSprite(newStage);
		libraryPart.refresh();
		setTab('scripts');
		scriptsPart.resetCategory();
		wasEdited = false;
	}

	protected function shouldShowGreenFlag():Boolean {
		return !(autostart || editMode);
	}

	protected function addParts():void {
		initTopBarPart();
		stagePart = getStagePart();
		libraryPart = getLibraryPart();
		tabsPart = new TabsPart(this);
		scriptsPart = new ScriptsPart(this);
		imagesPart = new ImagesPart(this);
		soundsPart = new SoundsPart(this);
		addChild(topBarPart);
		addChild(stagePart);
		addChild(libraryPart);
		addChild(tabsPart);
	}

	protected function getStagePart():StagePart {
		return new StagePart(this);
	}

	protected function getLibraryPart():LibraryPart {
		return new LibraryPart(this);
	}

	public function fixExtensionURL(javascriptURL:String):String {
		return javascriptURL;
	}

	// -----------------------------
	// UI Modes and Resizing
	//------------------------------

	public function setEditMode(newMode:Boolean):void {
		Menu.removeMenusFrom(stage);
		editMode = newMode;
		if (editMode) {
			interp.showAllRunFeedback();
			hide(playerBG);
			show(topBarPart);
			show(libraryPart);
			show(tabsPart);
			setTab(lastTab);
			stagePart.hidePlayButton();
			runtime.edgeTriggersEnabled = true;
		} else {
			addChildAt(playerBG, 0); // behind everything
			playerBG.visible = false;
			hide(topBarPart);
			hide(libraryPart);
			hide(tabsPart);
			setTab(null); // hides scripts, images, and sounds
		}
		stagePane.updateListWatchers();
		show(stagePart); // put stage in front
		fixLayout();
		stagePart.refresh();
	}

	protected function hide(obj:DisplayObject):void { if (obj.parent) obj.parent.removeChild(obj) }
	protected function show(obj:DisplayObject):void { addChild(obj) }
	protected function isShowing(obj:DisplayObject):Boolean { return obj.parent != null }

	public function onResize(e:Event):void {
		fixLayout();
	}

	public function fixLayout():void {
		var w:int = stage.stageWidth;
		var h:int = stage.stageHeight - 1; // fix to show bottom border...

		w = Math.ceil(w / scaleX);
		h = Math.ceil(h / scaleY);

		updateLayout(w, h);
	}

	protected function updateLayout(w:int, h:int):void {
		topBarPart.x = 0;
		topBarPart.y = 0;
		topBarPart.setWidthHeight(w, 28);

		var extraW:int = 2;
		var extraH:int = stagePart.computeTopBarHeight() + 1;
		if (editMode) {
			// adjust for global scale (from browser zoom)

			if (stageIsContracted) {
				stagePart.setWidthHeight(240 + extraW, 180 + extraH, 0.5);
			} else {
				stagePart.setWidthHeight(480 + extraW, 360 + extraH, 1);
			}
			stagePart.x = 5;
			stagePart.y = topBarPart.bottom() + 5;
			fixLoadProgressLayout();
		} else {
			drawBG();
			var pad:int = (w > 550) ? 16 : 0; // add padding for full-screen mode
			var scale:Number = Math.min((w - extraW - pad) / 480, (h - extraH - pad) / 360);
			scale = Math.max(0.01, scale);
			var scaledW:int = Math.floor((scale * 480) / 4) * 4; // round down to a multiple of 4
			scale = scaledW / 480;
			var playerW:Number = (scale * 480) + extraW;
			var playerH:Number = (scale * 360) + extraH;
			stagePart.setWidthHeight(playerW, playerH, scale);
			stagePart.x = int((w - playerW) / 2);
			stagePart.y = int((h - playerH) / 2);
			fixLoadProgressLayout();
			return;
		}
		libraryPart.x = stagePart.x;
		libraryPart.y = stagePart.bottom() + 18;
		libraryPart.setWidthHeight(stagePart.w, h - libraryPart.y);

		tabsPart.x = stagePart.right() + 5;
		tabsPart.y = topBarPart.bottom() + 5;
		tabsPart.fixLayout();

		// the content area shows the part associated with the currently selected tab:
		var contentY:int = tabsPart.y + 27;
		w -= tipsWidth();
		updateContentArea(tabsPart.x, contentY, w - tabsPart.x - 6, h - contentY - 5, h);
	}

	protected function updateContentArea(contentX:int, contentY:int, contentW:int, contentH:int, fullH:int):void {
		imagesPart.x = soundsPart.x = scriptsPart.x = contentX;
		imagesPart.y = soundsPart.y = scriptsPart.y = contentY;
		imagesPart.setWidthHeight(contentW, contentH);
		soundsPart.setWidthHeight(contentW, contentH);
		scriptsPart.setWidthHeight(contentW, contentH);

		if (mediaLibrary) mediaLibrary.setWidthHeight(topBarPart.w, fullH);
		if (frameRateGraph) {
			frameRateGraph.y = stage.stageHeight - frameRateGraphH;
			addChild(frameRateGraph); // put in front
		}

		/*SCRATCH::allow3d _wh*/ { if (isIn3D) render3D.onStageResize(); }
	}

	private function drawBG():void {
		var g:Graphics = playerBG.graphics;
		g.clear();
		g.beginFill(0);
		g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
	}

	// -----------------------------
	// Translations utilities
	//------------------------------

	public function translationChanged():void {
		// The translation has changed. Fix scripts and update the UI.
		// directionChanged is true if the writing direction (e.g. left-to-right) has changed.
		for each (var o:ScratchObj in stagePane.allObjects()) {
			o.updateScriptsAfterTranslation();
		}
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (var i:int = 0; i < uiLayer.numChildren; ++i) {
			var lw:ListWatcher = uiLayer.getChildAt(i) as ListWatcher;
			if (lw) lw.updateTranslation();
		}
		topBarPart.updateTranslation();
		stagePart.updateTranslation();
		libraryPart.updateTranslation();
		tabsPart.updateTranslation();
		updatePalette(false);
		imagesPart.updateTranslation();
		soundsPart.updateTranslation();
	}

	// -----------------------------
	// Menus
	//------------------------------
	public function showFileMenu(b:*):void {
		var m:Menu = new Menu(null, 'File', CSS.topBarColor, 28);
		m.addItem('New', createNewProject);
		m.addLine();

		// Derived class will handle this
		addFileMenuItems(b, m);

		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}

	protected function addFileMenuItems(b:*, m:Menu):void {
		m.addItem('Load Project', runtime.selectProjectFile);
		m.addItem('Save Project', exportProjectToFile);
		if (canUndoRevert()) {
			m.addLine();
			m.addItem('Undo Revert', undoRevert);
		} else if (canRevert()) {
			m.addLine();
			m.addItem('Revert', revertToOriginalProject);
		}

		if (b.lastEvent.shiftKey) {
			m.addLine();
			m.addItem('Save Project Summary', saveSummary);
		}
		if (b.lastEvent.shiftKey && jsEnabled) {
			m.addLine();
			m.addItem('Import experimental extension', function():void {
				function loadJSExtension(dialog:DialogBox):void {
					var url:String = dialog.getField('URL').replace(/^\s+|\s+$/g, '');
					if (url.length == 0) return;
					externalCall('ScratchExtensions.loadExternalJS', null, url);
				}
				var d:DialogBox = new DialogBox(loadJSExtension);
				d.addTitle('Load Javascript Scratch Extension');
				d.addField('URL', 120);
				d.addAcceptCancelButtons('Load');
				d.showOnStage(app.stage);
			});
		}
	}

	
	public function showEditMenu(b:*):void {
		var m:Menu = new Menu(null, 'More', CSS.topBarColor, 28);
		m.addItem('Undelete', runtime.undelete, runtime.canUndelete());
		m.addLine();
		m.addItem('Small stage layout', toggleSmallStage, true, stageIsContracted);
		m.addItem('Turbo mode', toggleTurboMode, true, interp.turboMode);
		addEditMenuItems(b, m);
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}

	protected function addEditMenuItems(b:*, m:Menu):void {
		m.addLine();
		m.addItem('Edit block colors', editBlockColors);
	}

	protected function editBlockColors():void {
		var d:DialogBox = new DialogBox();
		d.addTitle('Edit Block Colors');
		d.addWidget(new BlockColorEditor());
		d.addButton('Close', d.cancel);
		d.showOnStage(stage, true);
	}

	//help菜单_wh
	public function showHelpMenu(b:*):void {
		var m:Menu = new Menu(null, 'More', CSS.topBarColor, 28);
		m.addItem('CFunWorld', forum1);
		//m.addItem('Maoyouhui', forum5);
		//m.addItem('Scratch', forum3);
		//m.addItem('Arduino', forum4);
		m.addItem('Introduction', intro);
		//navigateToURL(new URLRequest("http://www.cfunworld.com"), "_blank");//论坛外链_wh
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}
	
	//网址外链_wh
	protected function forum1():void {
		navigateToURL(new URLRequest("http://www.cfunworld.com"), "_blank");//论坛外链_wh
	}	
	
	protected function forum3():void {
		navigateToURL(new URLRequest("https://scratch.mit.edu"), "_blank");//论坛外链_wh
	}
	protected function forum4():void {
		navigateToURL(new URLRequest("http://www.arduino.cc"), "_blank");//论坛外链_wh
	}
	protected function forum5():void {
		navigateToURL(new URLRequest("http://www.maoyouhui.org"), "_blank");//论坛外链_wh
	}
	
	//打开说明_wh
	protected function intro():void {
		var filei:File = new File(File.applicationDirectory.resolvePath("Introduction.pdf").nativePath);
		filei.openWithDefaultApplication();
	}
	
	public function checkUART():Array
	{
		var comArray:Array = new Array();
		for(var i:int =1;i<=16;i++)
		{
			{
				arduino.close();
				if(arduino.connect("COM"+i))
				{
					comArray.push("COM"+i);
				}
			}
		}
		arduino.close();
		return comArray;
	}
	
	public function fncArduinoData(aEvt: ArduinoConnectorEvent):void
	{
		try
		{
			comDataArrayOld = comDataArrayOld.concat(arduino.readBytesAsArray());//将接收到的数据放在comDataArrayOld数组中_wh
		}
		catch(Error)
		{
			return;
		}
		
		while(1)
		{
			comDataArray.length =0;
			for(var i:int = 0; i < comDataArrayOld.length; i++)
				comDataArray[i] = comDataArrayOld[i].charCodeAt(0);
			{
				if((comDataArray[0] == 0xee) || (comDataArrayOld.length == 0))
				{
					if(comDataArray[1] == 0x66)
					{
						switch(comDataArray[2])
						{
							case CFunPrims.ID_ReadDigital:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_ReadAnalog:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_ReadAFloat:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_ReadPFloat:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_ReadCap:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_ReadTRACK:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_ReadAVOID:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_ReadULTR:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_ReadPOWER:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							case CFunPrims.ID_READFRAREDR:if(comDataArray.length >= 8) comRevFlag = true;break;//数据接收完整判断_wh
							default:break;
						}
						break;
					}
					if(comDataArray.length >= 2)
						comDataArrayOld.shift();
					else
						break;
				}
				else
				{
					comDataArrayOld.shift();
				}
			}
		}
	}
	
	public function showCOMMenu(b:*):void {
		if(showCOMFlag)
			return;
		showCOMFlag = true;
		var m:Menu = new Menu(null, 'COM', CSS.topBarColor, 28);
		if(cmdBackNum == 0)
		{
			var comArrays:Array = new Array();
			//COM口未开启_wh
			if(comTrue == false)
			{
				comArrays = checkUART();
				for(var i:int = 0; i < comArrays.length; i++)
				{
					//comID = comArrays[i];//当前显示ID号赋给comID作为全局变量_wh
					switch(comArrays[i])
					{
						case 'COM1':m.addItem(comArrays[i], comOpen1);break;//选中则开启_wh
						case 'COM2':m.addItem(comArrays[i], comOpen2);break;//选中则开启_wh
						case 'COM3':m.addItem(comArrays[i], comOpen3);break;//选中则开启_wh
						case 'COM4':m.addItem(comArrays[i], comOpen4);break;//选中则开启_wh
						case 'COM5':m.addItem(comArrays[i], comOpen5);break;//选中则开启_wh
						case 'COM6':m.addItem(comArrays[i], comOpen6);break;//选中则开启_wh
						case 'COM7':m.addItem(comArrays[i], comOpen7);break;//选中则开启_wh
						case 'COM8':m.addItem(comArrays[i], comOpen8);break;//选中则开启_wh
						case 'COM9':m.addItem(comArrays[i], comOpen9);break;//选中则开启_wh
						case 'COM10':m.addItem(comArrays[i], comOpen10);break;//选中则开启_wh
						case 'COM11':m.addItem(comArrays[i], comOpen11);break;//选中则开启_wh
						case 'COM12':m.addItem(comArrays[i], comOpen12);break;//选中则开启_wh
						case 'COM13':m.addItem(comArrays[i], comOpen13);break;//选中则开启_wh
						case 'COM14':m.addItem(comArrays[i], comOpen14);break;//选中则开启_wh
						case 'COM15':m.addItem(comArrays[i], comOpen15);break;//选中则开启_wh
						case 'COM16':m.addItem(comArrays[i], comOpen16);break;//选中则开启_wh
						default:break;
					}
				}
			}
			else
			{
				arduino.close();
				comTrue = false;
				comDataArrayOld.splice();
//				var t1:Number = getTimer();
//				while(getTimer() - t1 < 100)
//					;
				if(arduino.connect(comIDTrue,ArduinoCOMRate))
				{
					comTrue = true;
					m.addItem(comIDTrue, comClose, true, true);
				}
				else
				{
					arduino.close();
					CFunConCir(0);
				}
			}
			m.addLine();
			
			if(blueFlag == false)
				m.addItem("Bluetooth", BlueOpen);
			else
				m.addItem("Bluetooth", BlueClose, true, true);
			
			//m.addLine();
			//m.addLine();
			
			m.addItem("Firmware", dofirm);
			m.addLine();
			m.addItem("Drive", dodrive);
			m.addLine();
		}
		
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
		
		if(UDFlag == false)
		{
			UDFlag = true;
			UpDialog.addTitle('Upload');
			UpDialog.addButton('Close',cancel);
			UpDialog.addText(Translator.map("uploading") + " ... ");
		}
		
		showCOMFlag = false;
	}
	
	protected function BlueOpen():void {
		blueFlag = true;
	}
	
	protected function BlueClose():void {
		blueFlag = false;
	}
	
	public function cancel():void {
		UpDialog.cancel();
		if((cmdBackNum < 70) && (cmdBackNum != 0))
			cmdBackNum = 70;
	}
	
	protected function dogeneral():void {
		ArduinoFirmN =  1;
		ArduinoCOMRate = 115200;
	}
	
	protected function dodrive():void {
		file0= new File(File.applicationDirectory.resolvePath("avrtool").nativePath);
		var file:File = new File();
		file = file.resolvePath(file0.nativePath+"/cmd.exe");
		nativePSInfo.executable = file;
		process.start(nativePSInfo);
		process.standardInput.writeUTFBytes("cd /d "+file0.nativePath+"\r\n");
		process.standardInput.writeUTFBytes("CH341SER"+"\r\n");
		process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);
		DriveFlag = 1;
	}
	
	protected function dofirm():void {
		if(comTrue)
			arduino.close();
		else
		{
			DialogBox.warnconfirm(Translator.map("error about firmware"),Translator.map("please open the COM"), null, app.stage);
			return;
		}
		
		file0= new File(File.applicationDirectory.resolvePath("avrtool").nativePath);
		var file:File = new File();
		file = file.resolvePath(file0.nativePath+"/cmd.exe");//调用cmd.exe_wh
		nativePSInfo.executable = file;
		process.start(nativePSInfo);
		process.standardInput.writeUTFBytes("cd /d "+file0.nativePath+"\r\n");
		
		
			process.standardInput.writeUTFBytes("avrdude -p m328p -c arduino -b 115200 -P "+comIDTrue+ " -U flash:w:CFun_uno.hex"+"\r\n");//avrdude命令行_wh
		
		UpDialog.setText(Translator.map("uploading") + " ... ");
		UpDialog.showOnStage(stage);
		ArduinoFirmFlag = 0;
		
		process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);//cmd返回数据处理事件_wh	
		delay1sTimer.start();
		cmdBackNum = 1;
	}
	
	protected function onTick(event:TimerEvent):void  
	{ 
		cmdBackNum ++;
		if(app.ArduinoRPFlag == true)
		{
			if(cmdBackNum == 71)//70s
			{
				{
					process.exit(nativePSInfo);//退出cmd.exe_wh
					process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);
					process2.start(nativePSInfo);//执行dos命令_wh
					process2.standardInput.writeUTFBytes("taskkill /f /im ArduinoUploader.exe /t"+"\r\n");
					UpDialog.setText(Translator.map("upload failed"));
				}
			}
			if(cmdBackNum == 73)//72s
			{
				cmdBackNum = 0;
				process2.exit(nativePSInfo);
				delay1sTimer.reset();
				app.ArduinoRPFlag = false;
				arduino.connect(comIDTrue,ArduinoCOMRate);
			}
		}
		else
		{
			if(cmdBackNum == 71)//70s
			{
				{
					process.exit(nativePSInfo);//退出cmd.exe_wh
					process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);
					process2.start(nativePSInfo);//执行dos命令_wh
					process2.standardInput.writeUTFBytes("taskkill /f /im avrdude.exe /t"+"\r\n");
					UpDialog.setText(Translator.map("upload failed"));
				}
			}
			if(cmdBackNum == 73)//72s
			{
				cmdBackNum = 0;
				process2.exit(nativePSInfo);
				delay1sTimer.reset();
				arduino.connect(comIDTrue,ArduinoCOMRate);
			}
		}
	}
	
	protected function onTimerComplete(event:TimerEvent):void 
	{ 
		process2.exit(nativePSInfo);
		delay1sTimer.reset();
		app.ArduinoRPFlag = false;
		cmdBackNum = 0;
		arduino.connect(comIDTrue,ArduinoCOMRate);
	} 
	
	public function cmdDataHandler(event:ProgressEvent):void {
		var str:String = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable); 
		trace(str);
		if(DriveFlag)
		{
			if(DriveFlag == 2)
			{
				process.exit(nativePSInfo);//退出cmd.exe_wh
				process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);
				DriveFlag = 0;
			}
			if(str.indexOf("CH341SER") != -1)
			{
				DriveFlag = 2;
			}	
		}
		else
		{
			if(app.ArduinoRPFlag == true)
			{
				if(str.indexOf("Compiliation:") != -1)
				{
					UpDialog.setText(Translator.map("uploading") + " ... ");
				}
				if(str.indexOf("Writing | ") != -1)
				{
					UpDialog.setText(Translator.map("upload success"));
					process.exit(nativePSInfo);//退出cmd.exe_wh
					process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);
					arduino.connect(comIDTrue,ArduinoCOMRate);
					delay1sTimer.reset();
					cmdBackNum = 0;
					app.ArduinoRPFlag = false;
				}
			}
			else
			{
				if(str.indexOf("avrtool>") != -1)
				{
					if(ArduinoFirmFlag)
					{
						if((cmdBackNum < 4) && (ArduinoFirmN == 1))
						{
							cmdBackNum = 70;
							ArduinoFirmFlag = 9;
						}
						else
						{
							if(ArduinoFirmFlag < 9)
							{
								UpDialog.setText(Translator.map("upload success"));
								process.exit(nativePSInfo);//退出cmd.exe_wh
								process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, cmdDataHandler);
								arduino.connect(comIDTrue,ArduinoCOMRate);
								delay1sTimer.reset();
								cmdBackNum = 0;
							}
						}
					}
					else
						ArduinoFirmFlag ++;
				}
			}
		}
	}
	
	protected function comOpen1():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM1';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen2():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM2';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen3():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM3';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen4():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM4';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen5():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM5';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen6():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM6';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen7():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM7';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen8():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM8';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen9():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM9';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen10():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM10';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen11():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM11';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen12():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM12';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen13():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM13';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen14():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM14';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen15():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM15';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	protected function comOpen16():void {
		comTrue = true;//COM口开启标志量赋值_wh
		comIDTrue = 'COM16';
		arduino.connect(comIDTrue,ArduinoCOMRate);
		arduino.addEventListener("socketData", fncArduinoData);//串口接收事件监测，在fncArduinoData函数中处理_wh
		arduino.writeString('UART Open Success '+comIDTrue+'\n');//_wh
		CFunConCir(1);
	}
	
	//显示并关闭选择的COM口
	protected function comClose():void {
		comTrue = false;//COM口开启标志量赋值_wh
		arduino.writeString('UART Close '+comIDTrue+'\n');//_wh
		arduino.flush();//清除缓存_wh
		arduino.close();//关闭COM口_wh
		//arduino.dispose();//释放_wh
		//arduino = new ArduinoConnector();//COM重建_wh
		CFunConCir(0);
		readCDFlag = false;//通信丢失提示框标志清零_wh
	}
	
	protected function canExportInternals():Boolean {
		return false;
	}

	private function showAboutDialog():void {
		DialogBox.notify(
			'Scratch 2.0 ' + versionString,
			'\n\nCopyright © 2012 MIT Media Laboratory' +
			'\nAll rights reserved.' +
			'\n\nPlease do not distribute!', stage);
	}

	protected function createNewProject(ignore:* = null):void {
		function clearProject():void {
			startNewProject('', '');
			setProjectName('Untitled');
			topBarPart.refresh();
			stagePart.refresh();
		}
		saveProjectAndThen(clearProject);
	}

	protected function saveProjectAndThen(postSaveAction:Function = null):void {
		// Give the user a chance to save their project, if needed, then call postSaveAction.
		function doNothing():void {}
		function cancel():void { d.cancel(); }
		function proceedWithoutSaving():void { d.cancel(); postSaveAction() }
		function save():void {
			d.cancel();
			exportProjectToFile(); // if this succeeds, saveNeeded will become false
			if (!saveNeeded) postSaveAction();
		}
		if (postSaveAction == null) postSaveAction = doNothing;
		if (!saveNeeded) {
			postSaveAction();
			return;
		}
		var d:DialogBox = new DialogBox();
		d.addTitle('Save project?');
		d.addButton('Save', save);
		d.addButton('Don\'t save', proceedWithoutSaving);
		d.addButton('Cancel', cancel);
		d.showOnStage(stage);
	}

	protected function exportProjectToFile(fromJS:Boolean = false):void {
		function squeakSoundsConverted():void {
			scriptsPane.saveScripts(false);
			var defaultName:String = (projectName().length > 0) ? projectName() + '.sb2' : 'project.sb2';
			var zipData:ByteArray = projIO.encodeProjectAsZipFile(stagePane);
			var file:FileReference = new FileReference();
			file.addEventListener(Event.COMPLETE, fileSaved);
			file.addEventListener(Event.CANCEL, fileNoSaved);
			file.save(zipData, fixFileName(defaultName));
		}
		function fileSaved(e:Event):void {
			if (!fromJS) setProjectName(e.target.name);
			if(closeWait == true)
				closeOK = true;
		}
		function fileNoSaved(e:Event):void {
			closeWait = false;
		}
		if (loadInProgress) return;
		var projIO:ProjectIO = new ProjectIO(this);
		projIO.convertSqueakSounds(stagePane, squeakSoundsConverted);
	}

	public static function fixFileName(s:String):String {
		// Replace illegal characters in the given string with dashes.
		const illegal:String = '\\/:*?"<>|%';
		var result:String = '';
		for (var i:int = 0; i < s.length; i++) {
			var ch:String = s.charAt(i);
			if ((i == 0) && ('.' == ch)) ch = '-'; // don't allow leading period
			result += (illegal.indexOf(ch) > -1) ? '-' : ch;
		}
		return result;
	}

	public function saveSummary():void {
		var name:String = (projectName() || "project") + ".txt";
		var file:FileReference = new FileReference();
		file.save(stagePane.getSummary(), fixFileName(name));
	}

	public function toggleSmallStage():void {
		setSmallStageMode(!stageIsContracted);
	}

	public function toggleTurboMode():void {
		interp.turboMode = !interp.turboMode;
		stagePart.refresh();
	}

	public function handleTool(tool:String, evt:MouseEvent):void { }

	public function showBubble(text:String, x:* = null, y:* = null, width:Number = 0):void {
		if (x == null) x = stage.mouseX;
		if (y == null) y = stage.mouseY;
		gh.showBubble(text, Number(x), Number(y), width);
	}

	// -----------------------------
	// Project Management and Sign in
	//------------------------------

	public function setLanguagePressed(b:IconButton):void {
		function setLanguage(lang:String):void {
			Translator.setLanguage(lang);
			languageChanged = true;
		}
		if (Translator.languages.length == 0) return; // empty language list
		var m:Menu = new Menu(setLanguage, 'Language', CSS.topBarColor, 28);
		if (b.lastEvent.shiftKey) {
			m.addItem('import translation file');
			m.addItem('set font size');
			m.addLine();
		}
		for each (var entry:Array in Translator.languages) {
			m.addItem(entry[1], entry[0]);
		}
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}

	public function startNewProject(newOwner:String, newID:String):void {
		runtime.installNewProject();
		projectOwner = newOwner;
		projectID = newID;
		projectIsPrivate = true;
		loadInProgress = false;
	}

	// -----------------------------
	// Save status
	//------------------------------

	public var saveNeeded:Boolean;

	public function setSaveNeeded(saveNow:Boolean = false):void {
		saveNow = false;
		// Set saveNeeded flag and update the status string.
		saveNeeded = true;
		if (!wasEdited) saveNow = true; // force a save on first change
		clearRevertUndo();
	}

	protected function clearSaveNeeded():void {
		// Clear saveNeeded flag and update the status string.
		function twoDigits(n:int):String { return ((n < 10) ? '0' : '') + n }
		saveNeeded = false;
		wasEdited = true;
	}

	// -----------------------------
	// Project Reverting
	//------------------------------

	protected var originalProj:ByteArray;
	private var revertUndo:ByteArray;

	public function saveForRevert(projData:ByteArray, isNew:Boolean, onServer:Boolean = false):void {
		originalProj = projData;
		revertUndo = null;
	}

	protected function doRevert():void {
		runtime.installProjectFromData(originalProj, false);
	}

	protected function revertToOriginalProject():void {
		function preDoRevert():void {
			revertUndo = new ProjectIO(Scratch.app).encodeProjectAsZipFile(stagePane);
			doRevert();
		}
		if (!originalProj) return;
		DialogBox.confirm('Throw away all changes since opening this project?', stage, preDoRevert);
	}

	protected function undoRevert():void {
		if (!revertUndo) return;
		runtime.installProjectFromData(revertUndo, false);
		revertUndo = null;
	}

	protected function canRevert():Boolean { return originalProj != null }
	protected function canUndoRevert():Boolean { return revertUndo != null }
	private function clearRevertUndo():void { revertUndo = null }

	public function addNewSprite(spr:ScratchSprite, showImages:Boolean = false, atMouse:Boolean = false):void {
		var c:ScratchCostume, byteCount:int;
		for each (c in spr.costumes) {
			if (!c.baseLayerData) c.prepareToSave()
			byteCount += c.baseLayerData.length;
		}
		if (!okayToAdd(byteCount)) return; // not enough room
		spr.objName = stagePane.unusedSpriteName(spr.objName);
		spr.indexInLibrary = 1000000; // add at end of library
		spr.setScratchXY(int(200 * Math.random() - 100), int(100 * Math.random() - 50));
		if (atMouse) spr.setScratchXY(stagePane.scratchMouseX(), stagePane.scratchMouseY());
		stagePane.addChild(spr);
		selectSprite(spr);
		setTab(showImages ? 'images' : 'scripts');
		setSaveNeeded(true);
		libraryPart.refresh();
		for each (c in spr.costumes) {
			if (ScratchCostume.isSVGData(c.baseLayerData)) c.setSVGData(c.baseLayerData, false);
		}
	}

	public function addSound(snd:ScratchSound, targetObj:ScratchObj = null):void {
		if (snd.soundData && !okayToAdd(snd.soundData.length)) return; // not enough room
		if (!targetObj) targetObj = viewedObj();
		snd.soundName = targetObj.unusedSoundName(snd.soundName);
		targetObj.sounds.push(snd);
		setSaveNeeded(true);
		if (targetObj == viewedObj()) {
			soundsPart.selectSound(snd);
			setTab('sounds');
		}
	}

	public function addCostume(c:ScratchCostume, targetObj:ScratchObj = null):void {
		if (!c.baseLayerData) c.prepareToSave();
		if (!okayToAdd(c.baseLayerData.length)) return; // not enough room
		if (!targetObj) targetObj = viewedObj();
		c.costumeName = targetObj.unusedCostumeName(c.costumeName);
		targetObj.costumes.push(c);
		targetObj.showCostumeNamed(c.costumeName);
		setSaveNeeded(true);
		if (targetObj == viewedObj()) setTab('images');
	}

	public function okayToAdd(newAssetBytes:int):Boolean {
		// Return true if there is room to add an asset of the given size.
		// Otherwise, return false and display a warning dialog.
		const assetByteLimit:int = 50 * 1024 * 1024; // 50 megabytes
		var assetByteCount:int = newAssetBytes;
		for each (var obj:ScratchObj in stagePane.allObjects()) {
			for each (var c:ScratchCostume in obj.costumes) {
				if (!c.baseLayerData) c.prepareToSave();
				assetByteCount += c.baseLayerData.length;
			}
			for each (var snd:ScratchSound in obj.sounds) assetByteCount += snd.soundData.length;
		}
		if (assetByteCount > assetByteLimit) {
			var overBy:int = Math.max(1, (assetByteCount - assetByteLimit) / 1024);
			DialogBox.notify(
				'Sorry!',
				'Adding that media asset would put this project over the size limit by ' + overBy + ' KB\n' +
				'Please remove some costumes, backdrops, or sounds before adding additional media.',
				stage);
			return false;
		}
		return true;
	}
	// -----------------------------
	// Flash sprite (helps connect a sprite on the stage with a sprite library entry)
	//------------------------------

	public function flashSprite(spr:ScratchSprite):void {
		function doFade(alpha:Number):void { box.alpha = alpha }
		function deleteBox():void { if (box.parent) { box.parent.removeChild(box) }}
		var r:Rectangle = spr.getVisibleBounds(this);
		var box:Shape = new Shape();
		box.graphics.lineStyle(3, CSS.overColor, 1, true);
		box.graphics.beginFill(0x808080);
		box.graphics.drawRoundRect(0, 0, r.width, r.height, 12, 12);
		box.x = r.x;
		box.y = r.y;
		addChild(box);
		Transition.cubic(doFade, 1, 0, 0.5, deleteBox);
	}

	// -----------------------------
	// Download Progress
	//------------------------------

	public function addLoadProgressBox(title:String):void {
		removeLoadProgressBox();
		lp = new LoadProgress();
		lp.setTitle(title);
		stage.addChild(lp);
		fixLoadProgressLayout();
	}

	public function removeLoadProgressBox():void {
		if (lp && lp.parent) lp.parent.removeChild(lp);
		lp = null;
	}

	private function fixLoadProgressLayout():void {
		if (!lp) return;
		var p:Point = stagePane.localToGlobal(new Point(0, 0));
		lp.scaleX = stagePane.scaleX;
		lp.scaleY = stagePane.scaleY;
		lp.x = int(p.x + ((stagePane.width - lp.width) / 2));
		lp.y = int(p.y + ((stagePane.height - lp.height) / 2));
	}

	// -----------------------------
	// Frame rate readout (for use during development)
	//------------------------------

	private var frameRateReadout:TextField;
	private var firstFrameTime:int;
	private var frameCount:int;

	protected function addFrameRateReadout(x:int, y:int, color:uint = 0):void {
		frameRateReadout = new TextField();
		frameRateReadout.autoSize = TextFieldAutoSize.LEFT;
		frameRateReadout.selectable = false;
		frameRateReadout.background = false;
		frameRateReadout.defaultTextFormat = new TextFormat(CSS.font, 12, color);
		frameRateReadout.x = x;
		frameRateReadout.y = y;
		addChild(frameRateReadout);
		frameRateReadout.addEventListener(Event.ENTER_FRAME, updateFrameRate);
	}

	private function updateFrameRate(e:Event):void {
		frameCount++;
		if (!frameRateReadout) return;
		var now:int = getTimer();
		var msecs:int = now - firstFrameTime;
		if (msecs > 500) {
			var fps:Number = Math.round((1000 * frameCount) / msecs);
			frameRateReadout.text = fps + ' fps (' + Math.round(msecs / frameCount) + ' msecs)';
			firstFrameTime = now;
			frameCount = 0;
		}
	}

	// TODO: Remove / no longer used
	private const frameRateGraphH:int = 150;
	private var frameRateGraph:Shape;
	private var nextFrameRateX:int;
	private var lastFrameTime:int;

	private function addFrameRateGraph():void {
		addChild(frameRateGraph = new Shape());
		frameRateGraph.y = stage.stageHeight - frameRateGraphH;
		clearFrameRateGraph();
		stage.addEventListener(Event.ENTER_FRAME, updateFrameRateGraph);
	}

	public function clearFrameRateGraph():void {
		var g:Graphics = frameRateGraph.graphics;
		g.clear();
		g.beginFill(0xFFFFFF);
		g.drawRect(0, 0, stage.stageWidth, frameRateGraphH);
		nextFrameRateX = 0;
	}

	private function updateFrameRateGraph(evt:*):void {
		var now:int = getTimer();
		var msecs:int = now - lastFrameTime;
		lastFrameTime = now;
		var c:int = 0x505050;
		if (msecs > 40) c = 0xE0E020;
		if (msecs > 50) c = 0xA02020;

		if (nextFrameRateX > stage.stageWidth) clearFrameRateGraph();
		var g:Graphics = frameRateGraph.graphics;
		g.beginFill(c);
		var barH:int = Math.min(frameRateGraphH, msecs / 2);
		g.drawRect(nextFrameRateX, frameRateGraphH - barH, 1, barH);
		nextFrameRateX++;
	}

	// -----------------------------
	// Camera Dialog
	//------------------------------

	public function openCameraDialog(savePhoto:Function):void {
		closeCameraDialog();
		cameraDialog = new CameraDialog(savePhoto);
		cameraDialog.fixLayout();
		cameraDialog.x = (stage.stageWidth - cameraDialog.width) / 2;
		cameraDialog.y = (stage.stageHeight - cameraDialog.height) / 2;
		addChild(cameraDialog);
	}

	public function closeCameraDialog():void {
		if (cameraDialog) {
			cameraDialog.closeDialog();
			cameraDialog = null;
		}
	}

	// Misc.
	public function createMediaInfo(obj:*, owningObj:ScratchObj = null):MediaInfo {
		return new MediaInfo(obj, owningObj);
	}

	static public function loadSingleFile(fileLoaded:Function, filters:Array = null):void {
		function fileSelected(event:Event):void {
			if (fileList.fileList.length > 0) {
				var file:FileReference = FileReference(fileList.fileList[0]);
				file.addEventListener(Event.COMPLETE, fileLoaded);
				file.load();
			}
		}

		var fileList:FileReferenceList = new FileReferenceList();
		fileList.addEventListener(Event.SELECT, fileSelected);
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			fileList.browse(filters);
		} catch(e:*) {}
	}

	// -----------------------------
	// External Interface abstraction
	//------------------------------

	public function externalInterfaceAvailable():Boolean {
		return false;
	}

	public function externalCall(functionName:String, returnValueCallback:Function = null, ...args):void {
		throw new IllegalOperationError('Must override this function.');
	}

	public function addExternalCallback(functionName:String, closure:Function):void {
		throw new IllegalOperationError('Must override this function.');
	}
}}
