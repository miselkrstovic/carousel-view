unit JvCarouselViewReg;

interface

{$I jvcl.inc}

uses
  SysUtils, Classes, TypInfo, Forms,
  {$IFDEF COMPILER6_UP}
  DesignEditors, DesignIntf,
  {$ELSE}
  DsgnIntf,
  {$ENDIF COMPILER6_UP}
  JvCarouselView;

type
  TJvCarouselViewItemsProperty = class(TClassProperty)
    function GetAttributes: TPropertyAttributes; override;
  public
    procedure Edit; override;
  end;

procedure Register;

implementation

{ TJvCarouselViewItemsProperty }

procedure TJvCarouselViewItemsProperty.Edit;
var
  F: TForm;
begin
  F := TForm.Create(Application);
  try
    with F do begin
      Caption := 'Editing items'; // TODO: Conactenate carousel view instance name
      BorderStyle := bsDialog;
      ShowModal;
    end;
    Modified; // TODO: Forcing modified flag
  finally
    F.Free;
  end;

end;

function TJvCarouselViewItemsProperty.GetAttributes: TPropertyAttributes;
begin
    Result := [paDialog];
end;

procedure Register;
begin
    RegisterComponents('Jv Visual', [TJvCarouselView]);
    RegisterPropertyEditor(TypeInfo(TJvCarouselItems), nil, '', TJvCarouselViewItemsProperty);
end;

end.
