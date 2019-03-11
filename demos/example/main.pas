{******************************************************************************}
{                                                                              }
{ Carousel View                                                                }
{                                                                              }
{ The contents of this file are subject to the MIT License (the "License");    }
{ you may not use this file except in compliance with the License.             }
{ You may obtain a copy of the License at https://opensource.org/licenses/MIT  }
{                                                                              }
{ Software distributed under the License is distributed on an "AS IS" basis,   }
{ WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for }
{ the specific language governing rights and limitations under the License.    }
{                                                                              }
{ Unit owner:    Mišel Krstović                                                }
{ Last modified: September 14, 2017                                            }
{                                                                              }
{******************************************************************************}

unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, JvCarouselView,
  JvTracker, AppEvnts, JvImageList, JvExControls, System.ImageList, Vcl.ImgList,
  Vcl.Imaging.pngimage, JvExExtCtrls, JvImage, Vcl.Imaging.jpeg, JvExtComponent,
  JvPanel, JvExStdCtrls, JvHtControls, JvLinkLabel;

type
  TfrmMain = class(TForm)
    JvCarouselView1: TJvCarouselView;
    JvImageList1: TJvImageList;
    pnlActionBar: TPanel;
    btnAddItem: TButton;
    edtShowHintMessage: TEdit;
    btnClear: TButton;
    lblCarouselView: TLabel;
    FontDialog1: TFontDialog;
    btnChangeFont: TButton;
    pnlItemInformation: TPanel;
    lblItemSubtitle: TLabel;
    lblItemTitle: TLabel;
    procedure btnAddItemClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnChangeFontClick(Sender: TObject);
    procedure FontDialog1Apply(Sender: TObject; Wnd: HWND);
    procedure JvCarouselView1ItemShowHint(var HintStr: string;
      var CanShow: Boolean);
    procedure JvCarouselView1ItemSelect(Sender: TObject; Item: TJvCarouselItem;
      Selected: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  CarouselView: TJvCarouselView;

implementation

{$R *.dfm}

procedure TfrmMain.btnChangeFontClick(Sender: TObject);
begin
  FontDialog1.Font := JvCarouselView1.Font;
  if (FontDialog1.Execute(self.Handle)) then begin
    JvCarouselView1.Font := FontDialog1.Font;
  end;
end;

procedure TfrmMain.btnClearClick(Sender: TObject);
begin
  JvCarouselView1.Clear;
end;

procedure TfrmMain.FontDialog1Apply(Sender: TObject; Wnd: HWND);
begin
  JvCarouselView1.Font := FontDialog1.Font;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  DoubleBuffered := true;
end;

procedure TfrmMain.JvCarouselView1ItemSelect(Sender: TObject;
  Item: TJvCarouselItem; Selected: Boolean);
begin
  if Assigned(Item) then begin
    ShowMessage(Item.Caption);
    if Item.Extras.Count>0 then begin
      lblItemTitle.Caption := Item.Extras.Strings[0];
      if Item.Extras.Count>=2 then begin
        lblItemSubtitle.Caption := Item.Extras.Strings[1];
      end;
    end;
  end;
end;

procedure TfrmMain.JvCarouselView1ItemShowHint(var HintStr: string;
  var CanShow: Boolean);
begin
  edtShowHintMessage.Text := HintStr;
end;

procedure TfrmMain.btnAddItemClick(Sender: TObject);
var
  Item: TJvCarouselItem;
begin
  Item := JvCarouselView1.Items.Add;
  Item.Caption := 'Package #' + IntToStr(JvCarouselView1.Items.Count);
  Item.ImageIndex := 0;

  Item.Extras.Add('Ut ultrices quam nisi, interdum dignissim est dictum id. Curabitur fringilla eu mi quis tempor. In quis vehicula mi. Fusce maximus erat nec eleifend lacinia. Vestibulum ut dui et elit varius tempor.');
  Item.Extras.Add('@basketball');
end;

end.
