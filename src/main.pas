unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, ExtDlgs, Windows, Registry, shellAPI;

const
  cPictureFilterList:string='JPG图片|*.jpg|PNG图片|*.png|GIF动图|*.gif';

type

  { Tmainform }

  Tmainform = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    ExtHere: TCheckBox;
    Label5: TLabel;
    Dopen: TOpenPictureDialog;
    picpreview: TImage;
    picname: TEdit;
    Label4: TLabel;
    Dsave: TSaveDialog;
    DExt: TSelectDirectoryDialog;
    TabSheet1: TTabSheet;
    targetfile: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    rarfile: TEdit;
    preview: TImage;
    jpgfile: TEdit;
    mainpage: TPageControl;
    encode: TTabSheet;
    decode: TTabSheet;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);

  private

  public
//    procedure DragFileProc(var Msg: TMessage);message WM_DROPFILES;
  end;
  //begin DropFiles
  TChangeWindowMessageFilter = function(msg: Cardinal; Action: Dword): BOOL; stdcall;
  //end DropFiles
var
  //begin DropFiles
  User32Module: THandle;
  ChangeWindowMessageFilterPtr: Pointer;
  //end DropFiles
  mainform: Tmainform;
implementation

{$R *.lfm}

{ Tmainform }

procedure Tmainform.Button1Click(Sender: TObject);
begin
  Dopen.Filter:=cPictureFilterList;
  if Dopen.Execute then begin//如果确实选取了一个文件名
     jpgfile.Text:=Dopen.FileName;
     preview.Picture.LoadFromFile(Dopen.FileName);//图片预览更新
  end;
  dsave.FilterIndex:=dopen.FilterIndex;
end;

procedure Tmainform.Button2Click(Sender: TObject);
begin
  Dopen.Filter:='RAR文件|*.rar';
  //如果确实选取了一个文件名
  if Dopen.Execute then rarfile.Text:=Dopen.FileName;
end;

procedure Tmainform.Button3Click(Sender: TObject);
var
  //定义非法字符集
  ErrorNameList:array[1..7] of char=('/','\','#','*','&','%','|');
  ok:boolean;
  i: Integer;
  ret: HINST;
  ans:unicodestring;
  CmdLine,Para:pwidechar;
begin
  if (jpgfile.text='') or (rarfile.text='') then
    showmessage('缺少图像文件或rar压缩文件，无法打包')
  else if Dsave.Execute then begin//如果指定了打包文件名
      targetfile.text:=dsave.filename;//更新打包文件名显示
      //文件名含有非法字符检测
      ok:=true;
      for i:=1 to 7 do if pos(targetfile.Text,ErrorNameList[i])<>0 then begin
        ok:=false;
        showmessage('文件名包含非法字符:/\#*&%|');
        break;
      end;
      //如果没有非法字符
      if ok then begin
        CmdLine:=pwidechar('cmd.exe');
        //参数表
        ans:='/c copy /b "'+jpgfile.text+'"+"'+rarfile.text+'" "'+targetfile.text+'"';
        //Para转化其为pwidechar格式给shellexecutew调用
        Para:=pwidechar(ans);
        ret:=shellexecutew(FindWindow(nil,PChar(mainform.Caption)),nil,CmdLine,Para,pwidechar(getcurrentdir),SW_HIDE);
        //处理返回值
        case ret of
          ERROR_FILE_NOT_FOUND:ans:='指定的文件没有找到';
          ERROR_PATH_NOT_FOUND:ans:='指定的地址没有找到';
          ERROR_BAD_FORMAT:ans:='EXE文件是一个无效的PE文件格式，或者EXE文件损坏了';
          SE_ERR_ASSOCINCOMPLETE:ans:='文件关联无效';
          SE_ERR_DDEBUSY:ans:='DDE事物无法完成相应，因为DDE事物正在被处理';
          SE_ERR_DDEFAIL:ans:='DDE事务失败。';
          SE_ERR_DDETIMEOUT:ans:='DDE事务无法完成响应，因为请求超时';
          SE_ERR_NOASSOC:ans:='没有关联程序';
          SE_ERR_SHARE:ans:='共享越界异常';
        else ans := '成功打包图种:'+targetfile.Text;end;//打包成功
        showmessage(ans);
      end;
    end;
end;

procedure Tmainform.Button4Click(Sender: TObject);
begin
  dopen.Filter:=cPictureFilterList;
  if dopen.Execute then begin//如果确实导入了一个图种文件
     picname.Text:=Dopen.FileName;
     picpreview.Picture.LoadFromFile(Dopen.FileName);
  end;
end;

procedure Tmainform.Button5Click(Sender: TObject);
var
  reg:Tregistry;
  s, dir: unicodeString;
  Para: PwideChar;
  ret: HINST;
  ans: TCaption;
begin
  //读注册表HKLM\SOFTWARE\WinRAR下exe64键值的值，得到WinRAR.exe所在位置
  reg:=Tregistry.Create(KEY_WRITE OR KEY_READ or KEY_WOW64_64KEY);
  reg.RootKey:=HKEY_LOCAL_MACHINE;
  if reg.OpenKey('SOFTWARE\WinRAR',false) then begin
    s:=reg.ReadString('exe64');
    if s='' then s:=reg.ReadString('exe');//如果装的是32位WinRAR
    if s='' then begin
      showmessage('需要正确安装WinRAR才能解包图种内容。');
      exit;
    end;
    reg.CloseKey;
  end;
  //检查是否选取了一个图种文件
  if picname.text='' then showmessage('文件名不能为空！')else begin
  //处理"解压到同一目录"复选框情形。被勾选的话，dir直接赋getcurrentdir。
  if Exthere.Checked then dir:=getcurrentdir else
    if DExt.Execute then dir:=Dext.filename else exit;
  //如果不以\结尾，结尾补\（当不是根目录时）
  if dir[length(dir)]<>'\' then dir:=dir+'\';
  //一般情况下WinRAR都会在Program Files地下，有空格，因此加""
  s:='"'+s+'"';
  //类似的转换和调用
  Para:=pwidechar(unicodestring(' x "'+picname.Text+'" "'+dir+'"'));
  ret:=shellexecutew(FindWindow(nil,PChar(mainform.Caption)),nil,pwidechar(s),para,pwidechar(getcurrentdir),SW_HIDE);
  case ret of
          ERROR_FILE_NOT_FOUND:ans:='指定的文件没有找到';
          ERROR_PATH_NOT_FOUND:ans:='指定的地址没有找到';
          ERROR_BAD_FORMAT:ans:='EXE文件是一个无效的PE文件格式，或者EXE文件损坏了';
          SE_ERR_ASSOCINCOMPLETE:ans:='文件关联无效';
          SE_ERR_DDEBUSY:ans:='DDE事物无法完成相应，因为DDE事物正在被处理';
          SE_ERR_DDEFAIL:ans:='DDE事务失败。';
          SE_ERR_DDETIMEOUT:ans:='DDE事务无法完成响应，因为请求超时';
          SE_ERR_NOASSOC:ans:='没有关联程序';
          SE_ERR_SHARE:ans:='共享越界异常';
        else ans := '成功解包图种:'+picname.Text;end;
        showmessage(ans);
  reg.Free;
  end;

end;

//begin DropFiles
//现用现加载USER32.dll
function CheckUser32Module: Boolean;
begin
 if User32Module=0 then User32Module:=safeLoadLibrary('USER32.DLL');
 Result:=User32Module>HINSTANCE_ERROR;
end;

function CheckUser32ModuleFunc(const Name: string; var ptr: Pointer): Boolean;
begin
 Result:=CheckUser32Module;
 if Result then
  begin
   ptr:=GetProcAddress(User32Module, PChar(Name));
   Result:=Assigned(ptr);
   if not Result then ptr:=Pointer(1);
  end;
end;
//call ChangeWindowMessageFilter() in USER32.DLL
function ChangeWindowMessageFilter(msg: Cardinal; Action: Dword): BOOL;
begin
 if (byte(ChangeWindowMessageFilterPtr) > 1) or
  CheckUser32ModuleFunc('ChangeWindowMessageFilter', ChangeWindowMessageFilterPtr) then
 Result:=TChangeWindowMessageFilter(ChangeWindowMessageFilterPtr)(Cardinal(msg), action)
 else Result:=false;
end;
//end DropFiles

procedure Tmainform.FormCreate(Sender: TObject);
const
  WM_COPYGLOBALDATA = 73;
  MSGFLT_ADD = 1;
begin
  mainpage.TabIndex:=0;
  //注册窗口可以接受拖入文件
  mainform.AllowDropFiles:=True;
  //为读取WinRAR安装路径，使用了Unit Regestry;这要求管理员权限
  //管理员权限使得程序运行在高MIC，因此不能接受explorer.exe(中MIC)拖拽来的程序图标
  //因此必须用ChangeWindowMessageFilter修改使得系统不block
  //而Lazarus的Windows单元里没有这个函数，所以要现加载USER32.DLL现用
  //见 DropFiles 部分
  try
     ChangeWindowMessageFilter(WM_COPYGLOBALDATA, MSGFLT_ADD);
     ChangeWindowMessageFilter(WM_DROPFILES, MSGFLT_ADD);
  except;
  end;
  if paramcount>0 then
    self.FormDropFiles(self,paramstr(1));
end;

procedure Tmainform.FormDestroy(Sender: TObject);
begin
   //释放dll
   if User32Module<>0 then FreeLibrary(User32Module);
end;

procedure Tmainform.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
var
  f:Thandle;
  ch:char;
  i:integer;//为批量处理预留
  s: String;
begin
  //直接跳文件尾部
  i:=0;
  s:=LowerCase(filenames[i]);

  if pos('.rar',s)=length(s)-3 then begin//说明.rar文件
    rarfile.Text:=s;
    mainpage.TabIndex:=0;
  end;

  if pos('.jpg',s)=length(s)-3 then//说明.jpg文件
    begin
      f:=fileopen(s,fmOpenRead);
      fileseek(f,-1,2);
      fileread(f,ch,sizeof(ch));
      fileclose(f);
      if ch=#217 then begin//说明这是一个纯图片
        jpgfile.Text:=s;
        preview.Picture.LoadFromFile(s);
        mainpage.TabIndex:=0;
        Dsave.FilterIndex:=1;
      end else begin      //说明这是一个图种
        picname.text:=s;
        picpreview.Picture.LoadFromFile(s);
        mainpage.TabIndex:=1;
      end;
    end;

  if pos('.png',s)=length(s)-3 then//说明.png文件
    begin
      f:=fileopen(s,fmOpenRead);
      fileseek(f,-1,2);
      fileread(f,ch,sizeof(ch));
      fileclose(f);
      if ch=#$82 then begin//说明这是一个纯图片
        jpgfile.Text:=s;
        preview.Picture.LoadFromFile(s);
        mainpage.TabIndex:=0;
        Dsave.FilterIndex:=2;
      end else begin      //说明这是一个图种
        picname.text:=s;
        picpreview.Picture.LoadFromFile(s);
        mainpage.TabIndex:=1;
      end;
    end;

  if pos('.gif',s)=length(s)-3 then//说明.gif文件
     begin
      f:=fileopen(s,fmOpenRead);
      fileseek(f,-1,2);
      fileread(f,ch,sizeof(ch));
      fileclose(f);
      if ch=#59 then begin//说明这是一个纯动图
        jpgfile.Text:=s;
        preview.Picture.LoadFromFile(s);
        mainpage.TabIndex:=0;
        Dsave.FilterIndex:=3;
      end else begin      //说明这是一个图种
        picname.text:=s;
        picpreview.Picture.LoadFromFile(s);
        mainpage.TabIndex:=1;
      end;
    end;
end;
end.

