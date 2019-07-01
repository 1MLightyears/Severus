unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, ExtDlgs, Windows, Registry, shellAPI;

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

  private

  public
    procedure DragFileProc(var Msg: TMessage);message WM_DROPFILES;
  end;

var
  mainform: Tmainform;
implementation

{$R *.lfm}

{ Tmainform }

procedure Tmainform.Button1Click(Sender: TObject);
begin
  Dopen.Filter:='JPG图片|*.jpg';
  if Dopen.Execute then begin//如果确实选取了一个文件名
     jpgfile.Text:=Dopen.FileName;
     preview.Picture.LoadFromFile(Dopen.FileName);//图片预览更新
  end;
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
  errornamelist:array[1..7] of char=('/','\','#','*','&','%','|');
  ok:boolean;
  i: Integer;
  ret: HINST;
  ans:unicodestring;
  cmdline, para:pwidechar;
begin
  if (jpgfile.text='') or (rarfile.text='') then
    showmessage('缺少jpg图像文件或rar压缩文件，无法打包')
  else if Dsave.Execute then begin//如果指定了打包文件名
      targetfile.text:=dsave.filename;//更新打包文件名显示
      //文件名含有非法字符检测
      ok:=true;
      for i:=1 to 7 do if pos(targetfile.Text,errornamelist[i])<>0 then begin
        ok:=false;
        showmessage('文件名包含非法字符:/\#*&%|');
        break;
      end;
      //如果没有非法字符
      if ok then begin
        //主程序cmd
        cmdline:=pwidechar('cmd.exe');
        //参数表
        ans:='/c copy /b "'+jpgfile.text+'"+"'+rarfile.text+'" "'+targetfile.text+'"';
        //para转化其为pwidechar格式给shellexecutew调用
        para:=pwidechar(ans);
        ret:=shellexecutew(FindWindow(nil,PChar(mainform.Caption)),nil,cmdline,para,pwidechar(getcurrentdir),SW_HIDE);
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
  dopen.Filter:='JPG图片|*.jpg';
  if dopen.Execute then begin//如果确实导入了一个图种文件

     picname.Text:=Dopen.FileName;
     picpreview.Picture.LoadFromFile(Dopen.FileName);

  end;
end;

procedure Tmainform.Button5Click(Sender: TObject);
var
  reg:Tregistry;
  s, dir: unicodeString;
  para: PwideChar;
  ret: HINST;
  ans: TCaption;
begin
  //检查是否选取了一个图种文件
  if picname.text='' then showmessage('文件名不能为空！')else begin
  //处理"解压到同一目录"复选框情形。被勾选的话，dir直接赋getcurrentdir。
  if Exthere.Checked then dir:=getcurrentdir else
    if DExt.Execute then dir:=Dext.filename else exit;
  //读注册表HKLM\SOFTWARE\WinRAR下exe64键值的值，得到WinRAR.exe所在位置
  reg:=Tregistry.Create(KEY_WRITE OR KEY_READ or KEY_WOW64_64KEY);
  reg.RootKey:=HKEY_LOCAL_MACHINE;
  if reg.OpenKey('SOFTWARE\WinRAR',false) then begin
    s:=reg.ReadString('exe64');
    if s='' then s:=reg.ReadString('exe');//如果装的是32位WinRAR
    reg.CloseKey;
  end;
  //如果不以\结尾，结尾补\（当不是根目录时）
  if dir[length(dir)]<>'\' then dir:=dir+'\';
  //一般情况下WinRAR都会在Program Files地下，有空格，因此加""
  s:='"'+s+'"';
  //类似的转换和调用
  para:=pwidechar(unicodestring(' x "'+picname.Text+'" "'+dir+'"'));
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

procedure Tmainform.FormCreate(Sender: TObject);

begin
  //注册窗口可以接受拖入文件
  DragAcceptFiles (self.Handle, True);
end;
//TODO:完成可以拖入文件的功能
procedure Tmainform.DragFileProc(var Msg: TMessage);
var
   filename,fileext: unicodestring;
   buffer:pwidechar;
begin
  DragQueryFile(Msg.wParam, 0, buffer, 255);
  filename:=unicodestring(buffer);
  //文件名就在filename里面了，
  fileext:=copy(filename,length(filename)-4,4);
  if fileext='.rar'then
    rarfile.Text:=filename
  else if fileext='.jpg' then
    jpgfile.Text:=filename;
  DragFinish(Msg.wParam);
end;

end.

