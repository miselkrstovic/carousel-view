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
{ The Original Code is JvCarouselView.pas.                                     }
{                                                                              }
{ Contains various graphics related classes and subroutines required for       }
{ creating a carousel view, and visual chart interaction.                      }
{                                                                              }
{ Credits:                                                                     }
{   Based on a flash tutorial by M. Hamilton                                   }
{   Heavily borrowed code from ComCtrls and CommCtrl.                          }
{                                                                              }
{ Unit owner:    Mišel Krstović                                                }
{ Last modified: September 14, 2017                                            }
{                                                                              }
{******************************************************************************}

unit JvCarouselView;

interface

{.$DEFINE THREAD_ENABLED}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls,
  ImgList, Contnrs, {DesignIntf, DesignEditors,} Math,
{$IFDEF THREAD_ENABLED}
  JvThreadTimer,
{$ENDIF}
  ImageList, System.UITypes, JvExExtCtrls, JVCLVer;

const
  LVIF_PARAM = $0004;
  UNDEFINED = -1;

type
  TPropertyAttributes = record
  end;

  TPropertyEditor = class
  public
    function GetAttributes: TPropertyAttributes; virtual;
    procedure Edit; virtual;
  end;

  TJvCarouselViewItemsProperty = class(TPropertyEditor)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TJvCarouselItem = class;
  TJvCarouselItems = class;
  TJvCarouselView = class;

  { TListItemsEnumerator }
  TJvCarouselViewItemsEnumerator = class
  private
    FIndex: Integer;
    FJvCarouselViewItems: TJvCarouselItems;
  public
    constructor Create(AJvCarouselViewItems: TJvCarouselItems);
    function GetCurrent: TJvCarouselItem;
    function MoveNext: Boolean;
    property Current: TJvCarouselItem read GetCurrent;
  end;

  TTJvCarouselViewItemClass = class of TJvCarouselItem;

  TCVUpdateEvent = procedure(Item: TJvCarouselItem) of object;

  TJvCarouselItem = class(TPersistent)
  private
    FOwner: TJvCarouselItems;
    FIndex: Integer;
    FOverlayIndex: TImageIndex;
    FStateIndex: TImageIndex;
    FDeleting: Boolean;
    FXScale: Double;
    FYScale: Double;
    FInitialWidth: Integer;
    FInitialHeight: Integer;
    FData: Pointer;
    FExtras: TStringList;
    FImageIndex: TImageIndex;
    FCaption: String;
    FHighlight: Boolean;

    FWidth: Integer;
    FHeight: Integer;
    FStretch: Boolean;
    FProportional: Boolean;
    FAngle: Double;
    FDirection: Boolean;
    FDepth: Double;
    FOnUpdate: TCVUpdateEvent;
    procedure SetXScale(const Value: Double);
    procedure SetYScale(const Value: Double);
    procedure SetData(const Value: Pointer);
    function GetCarouselView: TJvCarouselView;
    procedure SetCaption(const Value: String);
    procedure SetImage(const Index: Integer; const Value: TImageIndex);
    function GetIndex: Integer;
    function IsEqual(Item: TJvCarouselItem): Boolean;
    procedure SwapDepths(Depth: Double);
    function GetExtras: TStringList;
  protected
    procedure Paint;
  public
    Picture: TPicture;
    Left: Integer;
    Top: Integer;
    constructor Create(AOwner: TJvCarouselItems);
    destructor Destroy; override;
    property Caption: String read FCaption write SetCaption;
    property XScale: Double read FXScale write SetXScale;
    property YScale: Double read FYScale write SetYScale;
    property Data: Pointer read FData write SetData;
    property Extras: TStringList read GetExtras;
    property CarouselView: TJvCarouselView read GetCarouselView;
    property Owner: TJvCarouselItems read FOwner;
    property ImageIndex: TImageIndex index 0 read FImageIndex write SetImage;
    property OverlayIndex: TImageIndex index 1 read FOverlayIndex
      write SetImage;
    property StateIndex: TImageIndex index 2 read FStateIndex write SetImage;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property Stretch: Boolean read FStretch write FStretch;
    property Proportional: Boolean read FProportional write FProportional;
    property Index: Integer read GetIndex;
    property Highlight: Boolean read FHighlight write FHighlight;
    procedure Assign(Source: TJvCarouselItem);
    procedure Delete;
    property OnUpdate: TCVUpdateEvent read FOnUpdate write FOnUpdate;
  end;

  TJvCarouselItems = class(TPersistent)
  private
    FObjects: TObjectList;
    FObjectsCS: TMultiReadExclusiveWriteSynchronizer;

    FOwner: TJvCarouselView;
    FUpdateCount: Integer;
    FNoRedraw: Boolean;
    procedure ReadData(Stream: TStream);
    procedure ReadItemData(Stream: TStream);
    procedure WriteItemData(Stream: TStream);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function GetCount: Integer;
    // function GetHandle: HWND;
    function GetItem(Index: Integer): TJvCarouselItem;
    procedure SetItem(Index: Integer; Value: TJvCarouselItem);
    procedure SetUpdateState(Updating: Boolean);
  public
    constructor Create(AOwner: TJvCarouselView);
    destructor Destroy; override;
    function Add: TJvCarouselItem;
    function AddItem(Item: TJvCarouselItem; Index: Integer = UNDEFINED)
      : TJvCarouselItem;
    procedure Assign(Source: TPersistent); override;
    procedure BeginUpdate;
    procedure Clear;
    procedure Delete(Index: Integer);
    procedure EndUpdate;
    function GetEnumerator: TJvCarouselViewItemsEnumerator;
    function IndexOf(Value: TJvCarouselItem): Integer;
    function Insert(Index: Integer): TJvCarouselItem;
    property Count: Integer read GetCount;
    // property Handle: HWND read GetHandle;
    property Item[Index: Integer]: TJvCarouselItem read GetItem
      write SetItem; default;
    property Owner: TJvCarouselView read FOwner;
  end;

  TCVSelectItemEvent = procedure(Sender: TObject; Item: TJvCarouselItem;
    Selected: Boolean) of object;

  TCustomItemEffectEvent = procedure(Sender: TObject; Item: TJvCarouselItem) of object;

  TCaptionPosition = (cpNone, cpAbove, cpBelow);
  TItemEffect = (efNone, efShadow, efReflection, efCustom);
  TNavigationPosition = (npTop, npMiddle, npBottom, npRight, npLeft);
  TNavigationStyle = (nsDrawn, nsBitmap, nsCustom);
  TNavigationTheme = (ntLight, nsDark);
  TAtmosphereType = (atClear, atFog);

  TCarouselAtmosphere = class(TPersistent)
  private
    FType: TAtmosphereType;
    FVisibility: Integer;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Kind: TAtmosphereType read FType write FType default atFog;
    property Visibility: Integer read FVisibility write FVisibility default 0;
  end;

  TCarouselNavigation = class(TPersistent)
  private
    FEnabled: Boolean;
    FPosition: TNavigationPosition;
    FTheme: TNavigationTheme;
    FStyle: TNavigationStyle;
    FBitmapNext: TPicture;
    FBitmapPrevious: TPicture;
    procedure SetBitmapNext(const Value: TPicture);
    procedure SetBitmapPrevious(const Value: TPicture);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property Position: TNavigationPosition read FPosition write FPosition default npMiddle;
    property Theme: TNavigationTheme read FTheme write FTheme default ntLight;
    property Style: TNavigationStyle read FStyle write FStyle default nsDrawn;
    property BitmapNext: TPicture read FBitmapNext write SetBitmapNext;
    property BitmapPrevious: TPicture read FBitmapPrevious write SetBitmapPrevious;
  end;

  TCarouselDecor = class(TPersistent)
  private
    FCaptionPosition: TCaptionPosition;
    FItemEffect: TItemEffect;
  published
    property CaptionPosition: TCaptionPosition read FCaptionPosition write FCaptionPosition default cpNone;
    property ItemEffect: TItemEffect read FItemEffect write FItemEffect default efNone;
  end;

  TMotionStyle = (msFree, msNotched);
  TMotionFriction = class(TPersistent)
  private
    FKinetic: Double;
    FStatic: Double;
  published
    property Kinetic: Double read FKinetic write FKinetic;
    property Static_: Double read FStatic write FStatic;
  end;

  TCarouselMotion = class(TPersistent)
  private
    FDecay: Double;
    FStyle: TMotionStyle;
    FFriction: TMotionFriction;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property Decay: Double read FDecay write FDecay;
    property Style: TMotionStyle read FStyle write FStyle default msFree;
    property Friction: TMotionFriction read FFriction write FFriction;
  end;

  TJvCarouselView = class(TPaintBox)
  private
    { Private declarations }
    FAboutJVCL: TJVCLAboutInfo;
{$IFDEF THREAD_ENABLED}
    FTimer: TJvThreadTimer;
{$ELSE}
    FTimer: TTimer;
{$ENDIF}
    FSavedSort: TSortType;

    FOwnerData: Boolean;
    FSortType: TSortType;

    FHadInit: Boolean;


    procedure Init;
    procedure MouseMoveHandler(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure MouseDownHandler(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
    procedure MouseClickHandler(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
    procedure MouseEnterHandler(Sender: TObject);
    procedure UpdateHandler(Item: TJvCarouselItem);
    procedure ResizeHandler(Sender: TObject);
    procedure SetImages(Value: TCustomImageList);
    procedure SetItems(Value: TJvCarouselItems);
    function AreItemsStored: Boolean;
    procedure SetOwnerData(const Value: Boolean);
    function GetItem(Value: Integer): TJvCarouselItem;
    procedure SetSortType(const Value: TSortType);
    procedure TimerHandle(Sender: TObject);
    function GetHitTestItem: TJvCarouselItem;
    procedure SetHighlight(Item: TJvCarouselItem);
    procedure ClearHighlights;
    procedure DrawLeftNavigationButton(Canvas: TCanvas; Spacing,
      Radius: Integer; PenColor: TColor; BrushColor: TColor);
    procedure DrawRightNavigationButton(Canvas: TCanvas; Spacing,
      Radius: Integer; PenColor: TColor; BrushColor: TColor);
    procedure DrawNavigationButtons;
    function GetHitTestLeftNavigation: Boolean;
    function GetHitTestRightNavigation: Boolean;
    function GetAtmosphere: TCarouselAtmosphere;
    procedure SetAtmosphere(Value: TCarouselAtmosphere);
    function GetDecor: TCarouselDecor;
    procedure SetDecor(Value: TCarouselDecor);
    function GetMotion: TCarouselMotion;
    procedure SetMotion(const Value: TCarouselMotion);
    function GetNavigation: TCarouselNavigation;
    procedure SetNavigation(const Value: TCarouselNavigation);
  protected
    { Protected declarations }
    FRadiusX, FRadiusY, FCenterX, FCenterY: Integer;
    FMouseLastX: Integer;
    FMouseLastY: Integer;
    FSpeed: Double;
    FPerspective: Double;
    FRadiusDividerY: Integer;

    FAtmosphere: TCarouselAtmosphere;
    FDecor: TCarouselDecor;
    FMotion: TCarouselMotion;
    FNavigation: TCarouselNavigation;

    FOnSelectItem: TCVSelectItemEvent;
    FOnCustomEffect: TCustomItemEffectEvent;
    FOnShowHint: THintEvent;

    FImages: TCustomImageList;
    FImagesCS: TMultiReadExclusiveWriteSynchronizer;
    FCarouselViewItems: TJvCarouselItems;
    procedure Paint; override;
    property OwnerData: Boolean read FOwnerData write SetOwnerData
      default False;
    property SortType: TSortType read FSortType write SetSortType
      default stNone;
    function CreateCarouselViewItems: TJvCarouselItems; virtual;
    function IsRotatingRight(Speed: Double): Boolean;
    function IsRotatingLeft(Speed: Double): Boolean;
    function IsSwipeGesture(PreviousX: Integer; PreviousY: Integer; CurrentX: Integer; CurrentY: Integer;
      var Speed: Double): Boolean;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function AlphaSort: Boolean;
    procedure Freeze;
    procedure Unfreeze;
  published
    { Published declarations }
    property Atmosphere: TCarouselAtmosphere read GetAtmosphere write SetAtmosphere;
    property Decor: TCarouselDecor read GetDecor write SetDecor;
    property Motion: TCarouselMotion read GetMotion write SetMotion;
    property Navigation: TCarouselNavigation read GetNavigation write SetNavigation;

    property Images: TCustomImageList read FImages write SetImages;
    property Items: TJvCarouselItems read FCarouselViewItems write SetItems
      stored AreItemsStored;

    property Perspective: Double read FPerspective write FPerspective;

    property OnItemSelect: TCVSelectItemEvent read FOnSelectItem write FOnSelectItem;
    property OnItemShowHint: THintEvent read FOnShowHint write FOnShowHint;
    property OnCustomEffect: TCustomItemEffectEvent read FOnCustomEffect write FOnCustomEffect;

    property AboutJVCL: TJVCLAboutInfo read FAboutJVCL write FAboutJVCL stored False;
  end;

procedure Register;
function BlendColors(Color1, Color2: TColor; Opacity: Byte): TColor;

implementation

function Round(x: real): Int64;
begin
  result := Trunc(x);
end;

{ TJvCarouselItem }

procedure TJvCarouselItem.Assign(Source: TJvCarouselItem);
begin
  inherited Assign(Source);
end;

constructor TJvCarouselItem.Create(AOwner: TJvCarouselItems);
begin
  FOwner := AOwner;

  FOverlayIndex := UNDEFINED;
  FStateIndex := UNDEFINED;
  FImageIndex := UNDEFINED;

  GetCarouselView.FImagesCS.BeginRead;
  try
    Self.Width := GetCarouselView.Images.Width;
    Self.Height := GetCarouselView.Images.Height;
  finally
    GetCarouselView.FImagesCS.EndRead;
  end;

  FInitialWidth := Self.Width;
  FInitialHeight := Self.Height;

  Stretch := True;
  Proportional := True;

  FExtras := TStringList.Create;
  FExtras.Sorted := False;
  FExtras.Duplicates := TDuplicates.dupIgnore;

  Picture := TPicture.Create;
end;

procedure TJvCarouselItem.Delete;
begin
  if not FDeleting then
    Free;
end;

destructor TJvCarouselItem.Destroy;
begin
  FDeleting := True;
  FreeAndNil(Picture);
  FreeAndNil(FExtras);
  inherited Destroy;
end;

function TJvCarouselItem.GetCarouselView: TJvCarouselView;
begin
  Result := Owner.Owner;
end;

function TJvCarouselItem.GetExtras: TStringList;
begin
  result := FExtras;
end;

function TJvCarouselItem.GetIndex: Integer;
begin
  // TODO: OwnerData support is not properly implemented
  //       Double check if the following is implemented correctly
  if GetCarouselView.OwnerData then
  begin
    Result := FIndex
  end
  else
  begin
    Owner.FObjectsCS.BeginRead;
    try
      Result := Owner.FObjects.IndexOf(Self);
    finally
      Owner.FObjectsCS.EndRead;
    end;
  end;
end;

function TJvCarouselItem.IsEqual(Item: TJvCarouselItem): Boolean;
begin
  Result := (Caption = Item.Caption) and (Data = Item.Data);
end;

procedure TJvCarouselItem.Paint;
var
  ABitmap: TBitmap;
  bf: BLENDFUNCTION;
  ComputedAlpha: Integer;
  ColorTested: TColor;
  Canvas: TCanvas;
  DeviceContext: HDC;
begin
  inherited;
  try
    GetCarouselView.FImagesCS.BeginRead;
    try
      Canvas := GetCarouselView.Canvas;
      DeviceContext := Canvas.Handle;

      // Computing color test
      ColorTested := GetCarouselView.Color;
      if GetCarouselView.ParentColor then
      begin
        if GetCarouselView.Parent <> nil then
        begin
          if GetCarouselView.Parent is TForm then // TODO: What if it's something else?
          begin
            ColorTested := TForm(GetCarouselView.Parent).Color;
          end;
        end;
      end;

      if not(Picture.Icon.Empty) then
      begin
        ABitmap := TBitmap.Create;
        ABitmap.Transparent := True;
        ABitmap.PixelFormat := pf32bit;
        ABitmap.Width := GetCarouselView.Images.Width;
        ABitmap.Height := GetCarouselView.Images.Height;

        ABitmap.Assign(Picture.Icon);

        // Required for transparent text rendering with GDI
        SetBkMode(DeviceContext, Transparent);

        bf.BlendOp := AC_SRC_OVER;
        bf.BlendFlags := 0;
        bf.SourceConstantAlpha := 255;
        bf.AlphaFormat := AC_SRC_ALPHA;

        ComputedAlpha := (trunc(Self.FDepth) - 120) * 5;
        if ComputedAlpha > 255 then
          ComputedAlpha := 255;
        if ComputedAlpha < 0 then
          ComputedAlpha := 0;
        bf.SourceConstantAlpha := ComputedAlpha;

        AlphaBlend(DeviceContext, Self.Left, Self.Top, Self.Width, Self.Height,
          ABitmap.Canvas.Handle, 0, 0, ABitmap.Width, ABitmap.Height, bf);

        if Highlight then
        begin
          Canvas.Brush.Style := bsClear;
          Canvas.RoundRect(Self.Left - 5, Self.Top - 5, Self.Left + Self.Width +
            5, Self.Top + Self.Height, 10, 10);
        end;

        // Text color contrasting
        if ColorTested < $00808080 then begin
          SetTextColor(DeviceContext,
            ColorToRGB(BlendColors(ColorTested, clWhite, ComputedAlpha)));
        end else begin
          SetTextColor(DeviceContext,
            ColorToRGB(BlendColors(ColorTested, clBlack, ComputedAlpha)));
        end;

        if GetCarouselView.GetDecor.CaptionPosition<>cpNone then begin
          if length(Self.Caption) <> 0 then begin
            if GetCarouselView.GetDecor.CaptionPosition=cpAbove then begin
              TextOutW(DeviceContext,
                Self.Left + (Self.Width - Canvas.TextWidth(Self.Caption)) div 2,
                Self.Top - Canvas.TextHeight(Self.Caption) - 4, PWideChar(Self.Caption),
                length(Self.Caption));
            end else begin
              // Handle when caption is below
              TextOutW(DeviceContext,
                Self.Left + (Self.Width - Canvas.TextWidth(Self.Caption)) div 2,
                Self.Top + Self.Height + 4, PWideChar(Self.Caption),
                length(Self.Caption));
            end;
          end;
        end;
      end;
    finally
      GetCarouselView.FImagesCS.EndRead;
    end;
  finally
    FreeAndNil(ABitmap);
  end;
end;

function BlendColors(Color1, Color2: TColor; Opacity: Byte): TColor;
var
  r, g, b: Byte;
  c1, c2: PByteArray;
begin
  Color1 := ColorToRGB(Color1);
  Color2 := ColorToRGB(Color2);
  c1 := @Color1;
  c2 := @Color2;

  r := trunc(c1[0] + (c2[0] - c1[0]) * Opacity / 256);
  g := trunc(c1[1] + (c2[1] - c1[1]) * Opacity / 256);
  b := trunc(c1[2] + (c2[2] - c1[2]) * Opacity / 256);

  Result := RGB(r, g, b);
end;

procedure TJvCarouselItem.SetCaption(const Value: String);
begin
  if Value <> Caption then
  begin
    FCaption := trim(Value);
    if CarouselView.SortType in [stBoth, stText] then
      CarouselView.AlphaSort;
  end;
end;

procedure TJvCarouselItem.SetData(const Value: Pointer);
begin
  if Value <> Data then
  begin
    FData := Value;
    if CarouselView.SortType in [stBoth, stData] then
      CarouselView.AlphaSort;
  end;
end;

procedure TJvCarouselItem.SetImage(const Index: Integer;
  const Value: TImageIndex);
var
  LIcon: TIcon;
begin
  case Index of
    0:
      if Value <> FImageIndex then
      begin
        FImageIndex := Value;
        // TODO: OwnerData support is not properly implemented
        if not GetCarouselView.OwnerData then
        begin
          if GetCarouselView.Images <> nil then
          begin
            LIcon := TIcon.Create;
            try
              GetCarouselView.FImagesCS.BeginRead;
              try
                // This approach is taken to get the 32-bit bitmap
                // that includes the alpha channel, otherwise it gets
                // stripped
                GetCarouselView.Images.GetIcon(FImageIndex, LIcon);
                if LIcon.HandleAllocated then
                begin
                  Self.Picture.Icon.Assign(LIcon);
                end;
              finally
                GetCarouselView.FImagesCS.EndRead;
              end;
            finally
              FreeAndNil(LIcon);
            end;
          end;
        end;
      end;
    1:
      if Value <> FOverlayIndex then
      begin
        FOverlayIndex := Value;
        // TODO: OwnerData support is not properly implemented
        // if not GetCarouselView.OwnerData then
        // ListView_SetItemState(Handle, Self.Index,
        // IndexToOverlayMask(OverlayIndex + 1), LVIS_OVERLAYMASK);
      end;
    2:
      if Value <> FStateIndex then
      begin
        FStateIndex := Value;
        // TODO: OwnerData support is not properly implemented
        // if not GetCarouselView.OwnerData then
        // ListView_SetItemState(Handle, Self.Index,
        // IndexToStateImageMask(Value + 1), LVIS_STATEIMAGEMASK);
      end;
  end;
end;

procedure TJvCarouselItem.SetXScale(const Value: Double);
begin
  FXScale := Value;
  Width := round(FInitialWidth * (FXScale / 100));
end;

procedure TJvCarouselItem.SetYScale(const Value: Double);
begin
  FYScale := Value;
  Height := round(FInitialHeight * (FYScale / 100));
end;

procedure TJvCarouselItem.SwapDepths(Depth: Double);
begin
  FDepth := Depth;

  // if FDirection then begin
  // if (FAngle>0) and (Fangle<3*Pi/2) then Self.SendToBack;
  // if (FAngle<Pi) and (Fangle>3*Pi/2) then Self.SendToBack;
  // end else begin
  // Self.SendToBack;
  // end;
end;

{ TJvCarouselItems }

type
  PItemHeader = ^TItemHeader;

  TItemHeader = packed record
    Size, Count: Integer;
    Items: record end;
  end;

  PItemInfo = ^TItemInfo;

  TItemInfo = packed record
    ImageIndex: Integer;
    StateIndex: Integer;
    OverlayIndex: Integer;
    Data: Pointer;
    Caption: string[255];
  end;

  TItemDataInfo = packed record
    ImageIndex: Integer;
    StateIndex: Integer;
    OverlayIndex: Integer;
    Data: Pointer;
    CaptionLen: Byte;
    // String Caption of CaptionLen chars follows
  end;

  ShortStr = string[255];
  PShortStr = ^ShortStr;

constructor TJvCarouselItems.Create(AOwner: TJvCarouselView);
begin
  inherited Create;
  FOwner := AOwner;
  FObjectsCS := TMultiReadExclusiveWriteSynchronizer.Create;
  FObjects := TObjectList.Create(True);
end;

destructor TJvCarouselItems.Destroy;
begin
  Clear;
  FreeAndNil(FObjects);
  FreeAndNil(FObjectsCS);
  inherited Destroy;
end;

function TJvCarouselItems.Add: TJvCarouselItem;
begin
  Result := AddItem(nil, UNDEFINED);
end;

function TJvCarouselItems.Insert(Index: Integer): TJvCarouselItem;
begin
  Result := AddItem(nil, Index);
end;

function TJvCarouselItems.AddItem(Item: TJvCarouselItem; Index: Integer)
  : TJvCarouselItem;
var
  i: Integer;
begin
  if Item = nil then
  begin
    FObjectsCS.BeginWrite;
    try
      Result := TJvCarouselItem.Create(Self);
      Result.Caption := '';
      Result.OnUpdate := Owner.UpdateHandler;
      FObjects.Add(Result);

      // Recalculate angles
      for i := 0 to FObjects.Count - 1 do
      begin
        if Count <> 0 then
        begin
          TJvCarouselItem(FObjects.Items[i]).FAngle :=
            i * ((Pi * 2) / Count);
        end;
      end;
    finally
      FObjectsCS.EndWrite;
    end;
  end
  else
    Result := Item;
  if Index < 0 then
    Index := Count;
end;

function TJvCarouselItems.GetCount: Integer;
begin
  FObjectsCS.BeginRead;
  try
    Result := FObjects.Count;
  finally
    FObjectsCS.EndRead;
  end;
end;

function TJvCarouselItems.GetEnumerator: TJvCarouselViewItemsEnumerator;
begin
  Result := TJvCarouselViewItemsEnumerator.Create(Self);
end;

function TJvCarouselItems.GetItem(Index: Integer): TJvCarouselItem;
begin
  // TODO: OwnerData support is not properly implemented
  if Owner.OwnerData then
  begin
    Result := Owner.GetItem(Index);
  end
  else
  begin
    Result := Owner.GetItem(Index);
  end;
end;

function TJvCarouselItems.IndexOf(Value: TJvCarouselItem): Integer;
begin
  FObjectsCS.BeginRead;
  try
    Result := FObjects.IndexOf(Value);
  finally
    FObjectsCS.EndRead;
  end;
end;

procedure TJvCarouselItems.SetItem(Index: Integer;
  Value: TJvCarouselItem);
begin
  Item[Index] := Value;
  Item[Index].Assign(Value);
end;

procedure TJvCarouselItems.Clear;
begin
  FObjectsCS.BeginWrite;
  try
    FObjects.Clear;
  finally
    FObjectsCS.EndWrite;
  end;
end;

procedure TJvCarouselItems.BeginUpdate;
begin
  if FUpdateCount = 0 then
    SetUpdateState(True);
  Inc(FUpdateCount);
end;

procedure TJvCarouselItems.SetUpdateState(Updating: Boolean);
// var
// i: Integer;
begin
  if Updating then
  begin
    with Owner do
    begin
      FSavedSort := SortType;
      SortType := stNone;
    end;
    // for i := 0 to Owner.Columns.Count - 1 do begin
    // with Owner.Columns[i] as TListColumn do
    // if WidthType < 0 then
    // begin
    // FPrivateWidth := WidthType;
    // FWidth := Width;
    // DoChange;
    // end;
    // end;
    // SendMessage(Handle, WM_SETREDRAW, 0, 0);
    // if Owner.ColumnsShowing and Owner.ValidHeaderHandle then
    // SendMessage(Owner.FHeaderHandle, WM_SETREDRAW, 0, 0);
  end
  else if FUpdateCount = 0 then
  begin
    Owner.SortType := Owner.FSavedSort;
    // for i := 0 to Owner.Columns.Count - 1 do begin
    // with Owner.Columns[i] as TListColumn do
    // if FPrivateWidth < 0 then
    // begin
    // Width := FPrivateWidth;
    // FPrivateWidth := 0;
    // end;
    // end;
    FNoRedraw := True;
    try
      // SendMessage(Handle, WM_SETREDRAW, 1, 0);
      Owner.Invalidate;
    finally
      FNoRedraw := False;
    end;
    // if Owner.ColumnsShowing and Owner.ValidHeaderHandle then
    // SendMessage(Owner.FHeaderHandle, WM_SETREDRAW, 1, 0);
  end;
end;

procedure TJvCarouselItems.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount = 0 then
    SetUpdateState(False);
end;

procedure TJvCarouselItems.Assign(Source: TPersistent);
var
  Items: TJvCarouselItems;
  i: Integer;
begin
  if Source is TJvCarouselItems then
  begin
    Clear;
    Items := TJvCarouselItems(Source);
    for i := 0 to Items.Count - 1 do
      Add.Assign(Items[i]);
  end
  else
    inherited Assign(Source);
end;

procedure TJvCarouselItems.DefineProperties(Filer: TFiler);

  function WriteItems: Boolean;
  var
    i: Integer;
    Items: TJvCarouselItems;
  begin
    Items := TJvCarouselItems(Filer.Ancestor);
    if (Items = nil) then
      Result := Count > 0
    else if (Items.Count <> Count) then
      Result := True
    else
    begin
      Result := False;
      for i := 0 to Count - 1 do
      begin
        Result := not Item[i].IsEqual(Items[i]);
        if Result then
          Break;
      end
    end;
  end;

begin
  inherited DefineProperties(Filer);
  // Data property is platform specific (Ansi)
  // ItemData property stores data in Unicode
  Filer.DefineBinaryProperty('Data', ReadData, nil, False);
  Filer.DefineBinaryProperty('ItemData', ReadItemData, WriteItemData,
    WriteItems);
end;

procedure TJvCarouselItems.ReadData(Stream: TStream);
var
  i, Size, Len: Integer;
  ItemHeader: PItemHeader;
  ItemInfo: PItemInfo;
  PStr: PShortStr;
begin
  Clear;
  Stream.ReadBuffer(Size, SizeOf(Integer));
  ItemHeader := AllocMem(Size);
  try
    Stream.ReadBuffer(ItemHeader^.Count, Size - SizeOf(Integer));
    ItemInfo := @ItemHeader^.Items;
    PStr := nil;
    for i := 0 to ItemHeader^.Count - 1 do
    begin
      with Add do
      begin
        Caption := ItemInfo^.Caption;
        ImageIndex := ItemInfo^.ImageIndex;
        OverlayIndex := ItemInfo^.OverlayIndex;
        StateIndex := ItemInfo^.StateIndex;
        Data := ItemInfo^.Data;
        PStr := @ItemInfo^.Caption;
        Inc(Integer(PStr), length(PStr^) + 1);
        Len := 0;
      end;
      Inc(Integer(ItemInfo), SizeOf(TItemInfo) - 255 +
        length(ItemInfo.Caption) + Len);
    end;
  finally
    FreeMem(ItemHeader, Size);
  end;
end;

const
  ListItemStreamVersion: Byte = $01;

procedure TJvCarouselItems.ReadItemData(Stream: TStream);
var
  i, Size, ItemCount: Integer;
  StreamVersion: Byte;
  ItemInfo: TItemDataInfo;
  LStr: String;
begin
  Clear;
  Stream.ReadBuffer(StreamVersion, SizeOf(StreamVersion));
  if StreamVersion <> ListItemStreamVersion then
    Exit;
  Stream.ReadBuffer(Size, SizeOf(Integer));
  Stream.ReadBuffer(ItemCount, SizeOf(Integer));

  for i := 0 to ItemCount - 1 do
  begin
    Stream.ReadBuffer(ItemInfo, SizeOf(TItemDataInfo));
    with Add do
    begin
      ImageIndex := ItemInfo.ImageIndex;
      OverlayIndex := ItemInfo.OverlayIndex;
      StateIndex := ItemInfo.StateIndex;
      Data := ItemInfo.Data;

      // Read Caption
      SetLength(LStr, ItemInfo.CaptionLen);
      Stream.ReadBuffer(LStr[1], ItemInfo.CaptionLen * 2);
      Caption := LStr;
    end;
  end;
end;

procedure TJvCarouselItems.WriteItemData(Stream: TStream);
var
  ItemInfo: TItemDataInfo;
  LCaption: String;
  i, Size, L: Integer;
  LItemCount, LCaptionLen: Integer;

  function GetByteLength(const S: string): Integer;
  begin
    Result := length(S) * 2;
    if Result > 510 then
      Result := 510; // Max length for an item is 255 chars
  end;

begin
  Size := 0;
  for i := 0 to Count - 1 do
  begin
    L := GetByteLength(Item[i].Caption) + SizeOf(Byte); // Add length byte
    Inc(Size, SizeOf(TItemDataInfo) + L);
  end;

  LItemCount := Count;
  Stream.WriteBuffer(ListItemStreamVersion, SizeOf(Byte));
  Stream.WriteBuffer(Size, SizeOf(Integer));
  Stream.WriteBuffer(LItemCount, SizeOf(Integer));
  for i := 0 to Count - 1 do
  begin
    with Item[i] do
    begin
      // Write TItemDataInfo structure
      ItemInfo.ImageIndex := ImageIndex;
      ItemInfo.OverlayIndex := OverlayIndex;
      ItemInfo.StateIndex := StateIndex;
      ItemInfo.Data := Data;
      LCaption := Caption;
      LCaptionLen := length(LCaption);
      if LCaptionLen > 255 then
        LCaptionLen := 255;
      ItemInfo.CaptionLen := LCaptionLen;
      Stream.WriteBuffer(ItemInfo, SizeOf(TItemDataInfo));

      // Write Caption
      Stream.WriteBuffer(LCaption[1], ItemInfo.CaptionLen * 2);
    end;
  end;
end;

procedure TJvCarouselItems.Delete(Index: Integer);
begin
  Item[Index].Delete;
end;

{ TJvCarouselView }

procedure TJvCarouselView.MouseClickHandler(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
var
  Item: TJvCarouselItem;
  SwipeSpeed: Double;
begin
  // Restore the mouse cursor
  Cursor := crDefault;
  ReleaseCapture;

  try
    if IsSwipeGesture(FMouseLastX, FMouseLastY, X, Y, SwipeSpeed) then begin
      FSpeed := FSpeed + SwipeSpeed;
    end else begin
      // We reset all highlights in case the hit-test failed
      // which means the user clicked on blank space
      ClearHighlights;
      Item := GetHitTestItem;
      if Item <> nil then
      begin
        SetHighlight(Item);
        If Assigned(OnItemSelect) then begin
          {$IFDEF THREAD_ENABLED}
          TThread.CreateAnonymousThread(
            procedure
            begin
              TThread.Synchronize(nil,
                procedure
                begin
                  OnItemSelect(Sender, Item, Item.Highlight);
                end);
            end
          ).Start();
          {$ELSE}
          OnItemSelect(Sender, Item, Item.Highlight);
          {$ENDIF}
        end;
      end
      else if GetHitTestLeftNavigation then FSpeed := FSpeed - 0.04
      else if GetHitTestRightNavigation then FSpeed := FSpeed + 0.02;
    end;
  finally
    // Reset last mouse down position
    FMouseLastX := UNDEFINED;
    FMouseLastY := UNDEFINED;
  end;
end;

procedure TJvCarouselView.MouseDownHandler(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button=mbLeft then begin
    // Store mouse position for later usage
    FMouseLastX := X;
    FMouseLastY := Y;

    // Change cursor to hand pointer
    Cursor := crHandPoint;
    ReleaseCapture;
  end else begin
    FMouseLastX := UNDEFINED;
    FMouseLastY := UNDEFINED;
  end;
end;

procedure TJvCarouselView.MouseEnterHandler(Sender: TObject);
var
  Item: TJvCarouselItem;
  Hint: String;
  CanShow: Boolean;
begin
  if ShowHint then
  begin
    Item := GetHitTestItem;
    if Item <> nil then
    begin
      if Assigned(FOnShowHint) then
      begin
        Hint := trim(Item.Caption);
        CanShow := true;

        if Assigned(OnItemShowHint) then begin
          {$IFDEF THREAD_ENABLED}
          TThread.CreateAnonymousThread(
            procedure
            begin
              TThread.Synchronize(nil,
                procedure
                begin
                  OnItemShowHint(Hint, CanShow);
                end);
            end
          ).Start();
          {$ELSE}
          OnItemShowHint(Hint, CanShow);
          {$ENDIF}
        end;
      end;
    end;
  end;
end;

procedure TJvCarouselView.UpdateHandler(Item: TJvCarouselItem);
var
  S: Double;
begin
  Item.Left := round((cos(Item.FAngle) * FRadiusX) + FCenterX - Item.Width / 2);
  Item.Top := round((sin(Item.FAngle) * FRadiusY) + FCenterY - Item.Height / 2);

  if (FCenterY + FRadiusY) <> 0 then
  begin
    S := (Item.Top - FPerspective) / (FCenterY + FRadiusY);
  end;
  Item.XScale := S * 100;
  Item.YScale := S * 100;

  Item.FAngle := Item.FAngle + FSpeed;

  Item.SwapDepths(round(Item.XScale) + 100);
  Item.FDirection := FSpeed >= 0;
end;

procedure TJvCarouselView.Freeze;
begin
  FTimer.Enabled := False;
end;

function TJvCarouselView.GetAtmosphere: TCarouselAtmosphere;
begin
  result := FAtmosphere;
end;

function TJvCarouselView.GetDecor: TCarouselDecor;
begin
  result := FDecor;
end;

function TJvCarouselView.GetHitTestItem: TJvCarouselItem;
var
  i: Integer;
  HitPoint: TPoint;
begin
  Result := nil;
  HitPoint := Self.CalcCursorPos;

  Items.FObjectsCS.BeginRead;
  try
    for i := (Items.FObjects.Count - 1) downto 0 do
    begin
      if PtInRect(Rect(TJvCarouselItem(Items.FObjects.Items[i]).Left,
        TJvCarouselItem(Items.FObjects.Items[i]).Top,
        TJvCarouselItem(Items.FObjects.Items[i]).Left +
        TJvCarouselItem(Items.FObjects.Items[i]).Width,
        TJvCarouselItem(Items.FObjects.Items[i]).Top +
        TJvCarouselItem(Items.FObjects.Items[i]).Height), HitPoint) then
      begin
        Result := TJvCarouselItem(Items.FObjects.Items[i]);
        Break;
      end;
    end;
  finally
    Items.FObjectsCS.EndRead;
  end;
end;

function TJvCarouselView.GetItem(Value: Integer): TJvCarouselItem;
begin
  // TODO: OwnerData support is not properly implemented
  Items.FObjectsCS.BeginRead;
  try
    if OwnerData then
    begin
      Result := TJvCarouselItem(Items.FObjects.Items[Value]);
    end
    else
    begin
      Result := TJvCarouselItem(Items.FObjects.Items[Value]);
      // Result := Items[IItem];
    end
  finally
    Items.FObjectsCS.EndRead;
  end;
end;

function TJvCarouselView.GetMotion: TCarouselMotion;
begin
  result := FMotion;
end;

function TJvCarouselView.GetNavigation: TCarouselNavigation;
begin
  result := FNavigation;
end;

procedure TJvCarouselView.Init;
begin
  FRadiusX := 41 * Width div 100;
  FRadiusY := FRadiusX div FRadiusDividerY;

  FCenterX := Width div 2;
  FCenterY := Height div 2;

  FHadInit := true;
end;

function TJvCarouselView.AlphaSort: Boolean;
begin
  Result := True;
end;

function TJvCarouselView.AreItemsStored: Boolean;
begin
  Result := True;
end;

procedure TJvCarouselView.Clear;
begin
  FCarouselViewItems.BeginUpdate;
  try
    FCarouselViewItems.Clear;
  finally
    FCarouselViewItems.EndUpdate;
  end;
end;

procedure TJvCarouselView.ClearHighlights;
var
  i: Integer;
begin
  Items.FObjectsCS.BeginWrite;
  try
    for i := (Items.FObjects.Count - 1) downto 0 do
    begin
      TJvCarouselItem(Items.FObjects.Items[i]).Highlight := False;
    end;
  finally
    Items.FObjectsCS.EndWrite;
  end;
end;

constructor TJvCarouselView.Create(AOwner: TComponent);
begin
  inherited;

  OnMouseMove := MouseMoveHandler;
  OnResize := ResizeHandler;
  OnMouseDown := MouseDownHandler;
  OnMouseUp := MouseClickHandler;
  OnMouseEnter := MouseEnterHandler;

  FImagesCS := TMultiReadExclusiveWriteSynchronizer.Create;

  FAtmosphere := TCarouselAtmosphere.Create;
  FDecor := TCarouselDecor.Create;
  FMotion := TCarouselMotion.Create;
  FNavigation := TCarouselNavigation.Create;
  FCarouselViewItems := CreateCarouselViewItems;

  FMotion.Decay := 0.0005; // Constant
  FSpeed := 0;
  FPerspective := 0;
  FRadiusDividerY := 3;

{$IFDEF THREAD_ENABLED}
  FTimer := TJvThreadTimer.Create(Self);
  FTimer.KeepAlive := True;
  FTimer.Priority := tpNormal;
{$ELSE}
  FTimer := TTimer.Create(Self);
{$ENDIF}
  FTimer.Interval := 10;
  FTimer.OnTimer := TimerHandle;

  // Not required to have the thread running in design modes
  // to save cpu cycles
  FTimer.Enabled := not(csDesigning in ComponentState);
end;

function TJvCarouselView.CreateCarouselViewItems: TJvCarouselItems;
begin
  Result := TJvCarouselItems.Create(Self);
end;

destructor TJvCarouselView.Destroy;
begin
  FTimer.Enabled := False;
  FOnShowHint := nil;

  FreeAndNil(FTimer);
  FreeAndNil(FCarouselViewItems);
  FreeAndNil(FNavigation);
  FreeAndNil(FMotion);
  FreeAndNil(FDecor);
  FreeAndNil(FAtmosphere);
  FreeAndNil(FImagesCS);
  inherited;
end;

procedure TJvCarouselView.MouseMoveHandler(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if ssLeft in Shift then begin
    FSpeed := 0;
    // TODO: Ability to move the carousel interactively left and right while mouse button is down
  end;
end;

procedure TJvCarouselView.Paint;
var
  i: Integer;
begin
  inherited;

  Items.FObjectsCS.BeginRead;
  try
    for i := (Items.FObjects.Count - 1) downto 0 do
    begin
      TJvCarouselItem(Items.FObjects.Items[i]).Paint;
    end;

    DrawNavigationButtons;
  finally
    Items.FObjectsCS.EndRead;
  end;
end;

procedure TJvCarouselView.DrawNavigationButtons;
var
  Spacing: Integer;
  Radius: Integer;
  PenColor: TColor;
  BrushColor: TColor;
begin
  // Set drawing parameters
  Spacing := 5;
  Radius := 32;

  if getNavigation.Enabled then begin
    PenColor := $909090;
    BrushColor := $f0f0f0;
    // Call drawing methods
    DrawLeftNavigationButton(Canvas, Spacing, Radius, PenColor, BrushColor);
    DrawRightNavigationButton(Canvas, Spacing, Radius, PenColor, BrushColor);
  end;
end;

procedure TJvCarouselView.DrawRightNavigationButton(Canvas: TCanvas; Spacing: Integer; Radius: Integer; PenColor: TColor; BrushColor: TColor);
var
  Points: array of TPoint;
  Bounds: TRect;
begin
  Bounds := BoundsRect;
  Bounds.Offset(-Bounds.Left, -Bounds.Top);

  Canvas.Pen.Color := PenColor;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := $ffffff;
  Canvas.RoundRect(
    Bounds.Right - Radius - Spacing, Bounds.Bottom - Spacing - Radius,
    Bounds.Right - Spacing, Bounds.Bottom - Spacing,
    5, 5);
  Canvas.Brush.Color := BrushColor;
  SetLength(Points, 3);
  Points[0] := Point(Bounds.Right - Radius - Spacing + 11, Bounds.Bottom - Spacing - Radius + 8);
  Points[1] := Point(Bounds.Right - Radius - Spacing + 24, Bounds.Bottom - Spacing - Radius + 16);
  Points[2] := Point(Bounds.Right - Radius - Spacing + 11, Bounds.Bottom - Spacing - 8);
  Canvas.Polygon(Points);
end;

procedure TJvCarouselView.DrawLeftNavigationButton(Canvas: TCanvas; Spacing: Integer; Radius: Integer; PenColor: TColor; BrushColor: TColor);
var
  Points: array of TPoint;
  Bounds: TRect;
begin
  Bounds := BoundsRect;
  Bounds.Offset(-Bounds.Left, -Bounds.Top);

  Canvas.Pen.Color := PenColor;
  Canvas.Pen.Width := 1;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := $ffffff;
  Canvas.RoundRect(
    Bounds.Left + Spacing, Bounds.Bottom - Spacing - Radius,
    Bounds.Left + Radius + Spacing, Bounds.Bottom - Spacing,
    5, 5);
  Canvas.Brush.Color := BrushColor;
  SetLength(Points, 3);
  Points[0] := Point(Bounds.Left + Spacing + Radius - 11, Bounds.Bottom - Spacing - Radius + 8);
  Points[1] := Point(Bounds.Left + Spacing + 7, Bounds.Bottom - Spacing - Radius + 16);
  Points[2] := Point(Bounds.Left + Spacing + Radius - 11, Bounds.Bottom - Spacing - 8);
  Canvas.Polygon(Points);
end;

function TJvCarouselView.GetHitTestRightNavigation: Boolean;
var
  HitPoint: TPoint;
  Spacing: Integer;
  Radius: Integer;
  Bounds: TRect;
begin
  Bounds := BoundsRect;
  Bounds.Offset(-Bounds.Left, -Bounds.Top);
  Spacing := 5;
  Radius := 32;
  HitPoint := Self.CalcCursorPos;

  if PtInRect(Rect(Bounds.Right - Radius - Spacing, Bounds.Bottom - Spacing - Radius,
    Bounds.Right - Spacing, Bounds.Bottom - Spacing), HitPoint) then
  begin
    Result := True;
  end else begin
    Result := False;
  end;
end;

function TJvCarouselView.GetHitTestLeftNavigation: Boolean;
var
  HitPoint: TPoint;
  Spacing: Integer;
  Radius: Integer;
  Bounds: TRect;
begin
  Bounds := BoundsRect;
  Bounds.Offset(-Bounds.Left, -Bounds.Top);
  Spacing := 5;
  Radius := 32;
  HitPoint := Self.CalcCursorPos;

  if PtInRect(Rect(Bounds.Left + Spacing, Bounds.Bottom - Spacing - Radius,
    Bounds.Left + Radius + Spacing, Bounds.Bottom - Spacing), HitPoint) then
  begin
    Result := True;
  end else begin
    Result := False;
  end;
end;

procedure TJvCarouselView.ResizeHandler(Sender: TObject);
begin
  Init;
end;

procedure TJvCarouselView.SetAtmosphere(Value: TCarouselAtmosphere);
begin
  if Assigned(Atmosphere) then FAtmosphere := Value;
end;

procedure TJvCarouselView.SetDecor(Value: TCarouselDecor);
begin
  if Assigned(Decor) then FDecor := Value;
end;

procedure TJvCarouselView.SetHighlight(Item: TJvCarouselItem);
begin
  if Item <> nil then
  begin
    Item.Highlight := True;
  end;
end;

procedure TJvCarouselView.SetImages(Value: TCustomImageList);
begin
  if Value = FImages then
    Exit;

  FImagesCS.BeginWrite;
  try
    FImages := Value;
  finally
    FImagesCS.EndWrite;
  end;

  if Value <> nil then
  begin
    Value.FreeNotification(Self);
    // if (Self <> nil) and ([csDesigning, csLoading] * Self.ComponentState = [csDesigning])
    // and not Self.Transparent and (Value.BkColor = clNone) then Self.Transparent := True;
  end;
  // Changed(false);
end;

procedure TJvCarouselView.SetItems(Value: TJvCarouselItems);
begin
  FCarouselViewItems.Assign(Value);
end;

procedure TJvCarouselView.SetMotion(const Value: TCarouselMotion);
begin
  if Assigned(Value) then FMotion := Value;  
end;

procedure TJvCarouselView.SetNavigation(const Value: TCarouselNavigation);
begin
  if Assigned(Value) then FNavigation := Value;
end;

procedure TJvCarouselView.SetOwnerData(const Value: Boolean);
begin
  // TODO: OwnerData support is not properly implemented
  if FOwnerData <> Value then
  begin
    Items.Clear;
    FOwnerData := Value;
  end;
end;

procedure TJvCarouselView.SetSortType(const Value: TSortType);
begin
  FSortType := Value;
end;

procedure TJvCarouselView.TimerHandle(Sender: TObject);
var
  i: Integer;
begin
  FTimer.Enabled := False;

  try
    if not(FHadInit) then Init;

    Items.FObjectsCS.BeginWrite;
    try
      for i := (Self.Items.FObjects.Count - 1) downto 0 do
      begin
        if Assigned(TJvCarouselItem(Self.Items.FObjects.Items[i])
          .OnUpdate) then
        begin
          TJvCarouselItem(Items.FObjects.Items[i])
            .OnUpdate(TJvCarouselItem(Items.FObjects.Items[i]));
        end;
      end;

      // Speed deminishing
      if IsRotatingRight(FSpeed) then FSpeed := FSpeed - FMotion.Decay;
      if IsRotatingLeft(FSpeed) then FSpeed := FSpeed + FMotion.Decay;
      if (Abs(FSpeed) < FMotion.Decay) then FSpeed := 0;
    finally
      Items.FObjectsCS.EndWrite;
    end;
    Invalidate;
  finally
    FTimer.Enabled := True;
  end;
end;

function TJvCarouselView.IsRotatingRight(Speed: Double): Boolean;
begin
  result := Speed > 0;
end;

function TJvCarouselView.IsSwipeGesture(PreviousX: Integer; PreviousY: Integer; CurrentX: Integer; CurrentY: Integer;
      var Speed: Double): Boolean;
var
  Swiped: Boolean;
begin
  Swiped := not((PreviousX + PreviousY) = -2);
  if Swiped then begin
    if abs(PreviousX-CurrentX)>48 then begin // Pixels threshold
      Speed := ((PreviousX-CurrentX) * 1.10) / 5000;
    end else begin
      Speed := 0;
      Swiped := false;
    end;
  end else begin
    Speed := 0;
  end;
  result := Swiped;
end;

function TJvCarouselView.IsRotatingLeft(Speed: Double): Boolean;
begin
  result := Speed < 0;
end;

procedure TJvCarouselView.Unfreeze;
begin
  FTimer.Enabled := True;
end;

{ TJvCarouselViewItemsEnumerator }

constructor TJvCarouselViewItemsEnumerator.Create(AJvCarouselViewItems
  : TJvCarouselItems);
begin
  inherited Create;
  FIndex := UNDEFINED;
  FJvCarouselViewItems := AJvCarouselViewItems;
end;

function TJvCarouselViewItemsEnumerator.GetCurrent: TJvCarouselItem;
begin
  Result := FJvCarouselViewItems[FIndex];
end;

function TJvCarouselViewItemsEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < FJvCarouselViewItems.Count - 1;
  if Result then
    Inc(FIndex);
end;

procedure Register;
begin
  RegisterComponents('Jv Visual', [TJvCarouselView]);
  // todo:  RegisterPropertyEditor(TypeInfo(TJvCarouselItems), nil, '', TJvCarouselViewItemsProperty);
end;

{ TJvCarouselViewItemsProperty }

procedure TJvCarouselViewItemsProperty.Edit;
begin
  inherited;
  // TODO: Needs implementation
end;

function TJvCarouselViewItemsProperty.GetAttributes: TPropertyAttributes;
begin
  // TODO: Needs implementation
end;

{ TPropertyEditor }

procedure TPropertyEditor.Edit;
begin
  // TODO: Needs implementation
end;

function TPropertyEditor.GetAttributes: TPropertyAttributes;
begin
  // TODO: Needs implementation
end;

{ TCarouselNavigation }

constructor TCarouselNavigation.Create;
begin
  FBitmapNext := TPicture.Create;
  FBitmapPrevious := TPicture.Create;
end;

destructor TCarouselNavigation.Destroy;
begin
  FreeAndNil(FBitmapNext);
  FreeAndNil(FBitmapPrevious);
  inherited Destroy;
end;

procedure TCarouselNavigation.SetBitmapNext(const Value: TPicture);
begin
  FBitmapNext := Value;
end;

procedure TCarouselNavigation.SetBitmapPrevious(const Value: TPicture);
begin
  FBitmapPrevious := Value;
end;

{ TCarouselMotion }

constructor TCarouselMotion.Create;
begin
  FFriction := TMotionFriction.Create;
end;

destructor TCarouselMotion.Destroy;
begin
  FreeAndNil(FFriction);
  inherited;
end;

{ TCarouselAtmosphere }

constructor TCarouselAtmosphere.Create;
begin

end;

destructor TCarouselAtmosphere.Destroy;
begin

  inherited;
end;

end.
