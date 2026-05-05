///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.mormot;

interface

uses sysutils,
     classes,
     Variants,
     gs.Json,
     mormot.core.base,
     mormot.core.variants;

type

TgsJsonImplMormot = class(TInterfacedObject, igsJson)
private
protected
  FJson : variant;
  FOwned : boolean;
  // For bare values that TDocVariantData cannot store at root level
  FBareValue : string;
  FBareType  : TgsJsonElementType;
  function DVD : PDocVariantData;
  procedure EnsureObj;
  procedure EnsureArr;
public
  constructor Create; virtual;
  destructor Destroy; override;

  function parse(aJsonStr : string) : igsJson;
  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;
  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;
  function put(name : string; val : igsJson) : igsJson; overload;
  function put(val : igsJson) : igsJson; overload;

  function stringify(var aStr : string) : igsJson; overload;
  function stringify : string; overload;

  function get(name : string; var value : string) : igsJson; overload;
  function get(index : integer; var value : string) : igsJson; overload;
  function get(name : string; var value : integer) : igsJson; overload;
  function get(index : integer; var value : integer) : igsJson; overload;
  function get(name : string; var value : Double) : igsJson; overload;
  function get(index : integer; var value : Double) : igsJson; overload;
  function get(name : string; var value : Boolean) : igsJson; overload;
  function get(index : integer; var value : Boolean) : igsJson; overload;
  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  function jsonElementCount : integer;
  function jsonElementType(index : integer) : TgsJsonElementType;
  function jsonType : TgsJsonElementType;
  function jsonElementName(index : integer) : string;

  function clear : igsJson;

  function asString(name : String) : string;
  function asInteger(name : String) : integer;
  function asNumber(name : String) : double;
  function asBoolean(name : String) : Boolean;
  function asObj(name : String) : igsJson; overload;
  function asObj(index : integer) : igsJson; overload;

  function add(val : igsJson) : igsJson; overload;
  function add(val : double) : igsJson; overload;
  function add(val : integer) : igsJson; overload;
  function add(val : string) : igsJson; overload;
  function add(val : byte) : igsJson; overload;
  function add(val : boolean) : igsJson; overload;

  function isNameExists(name: String): boolean;

  function ToObj : igsJson;
  function ToArray : igsJson;
end;

TgsJsonImplMormotFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

uses mormot.core.unicode,
     mormot.core.text,
     mormot.core.json;

{ Helpers }

function VariantToElementType(const v : variant) : TgsJsonElementType;
var
  vt : word;
  p : PDocVariantData;
begin
  result := TgsJsonElementType.etEmpty;
  vt := VarType(v);
  if vt <= varNull then
    result := TgsJsonElementType.etNull
  else if vt = varBoolean then
    result := TgsJsonElementType.etBoolean
  else if vt in [varSmallInt, varInteger, varSingle, varDouble, varCurrency,
                 varShortInt, varByte, varWord, varLongWord, varInt64, varUInt64] then
    result := TgsJsonElementType.etNumber
  else if (vt = varString) or (vt = varOleStr) or (vt = varUString) then
    result := TgsJsonElementType.etString
  else if DocVariantType.IsOfType(v) then begin
    p := @TDocVariantData(v);
    if p^.Kind = dvArray then
      result := TgsJsonElementType.etJsonArray
    else
      result := TgsJsonElementType.etJson;
  end;
end;

procedure ExtractMormotValue(const AValue : variant; var value : igsJson);
var
  child : TgsJsonImplMormot;
begin
  if not assigned(value) then
    value := TgsJsonImplMormot.Create;
  child := TgsJsonImplMormot(value);
  child.FBareType := TgsJsonElementType.etEmpty;
  child.FBareValue := '';
  child.FOwned := true;

  if DocVariantType.IsOfType(AValue) then begin
    child.FJson := AValue;
  end
  else begin
    // Bare value stored in the variant
    var vt := VarType(AValue);
    if vt <= varNull then begin
      child.FBareType := TgsJsonElementType.etNull;
      child.FBareValue := 'null';
    end
    else if vt = varBoolean then begin
      child.FBareType := TgsJsonElementType.etBoolean;
      if boolean(AValue) then
        child.FBareValue := 'true'
      else
        child.FBareValue := 'false';
    end
    else if (vt = varString) or (vt = varOleStr) or (vt = varUString) then begin
      child.FBareType := TgsJsonElementType.etString;
      child.FBareValue := string(AValue);
    end
    else begin
      child.FBareType := TgsJsonElementType.etNumber;
      child.FBareValue := VarToStr(AValue);
    end;
  end;
end;

procedure AddArrayOfConst(p : PDocVariantData; const vals : array of const);
var
  i : integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString        : p^.AddItem(variant(String(vals[i].VString^)));
      vtWideString    : p^.AddItem(variant(String(WideString(vals[i].VWideString))));
      vtUnicodeString : p^.AddItem(variant(String(UnicodeString(vals[i].VUnicodeString))));
      vtInteger       : p^.AddItem(variant(vals[i].VInteger));
      System.vtBoolean: p^.AddItem(variant(Boolean(vals[i].VBoolean)));
      vtExtended      : p^.AddItem(variant(Double(vals[i].VExtended^)));
      vtInt64         : p^.AddItem(variant(vals[i].VInt64^));
    end;
  end;
end;

{ TgsJsonImplMormot }

constructor TgsJsonImplMormot.Create;
begin
  FOwned := true;
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
  VarClear(FJson);
end;

destructor TgsJsonImplMormot.Destroy;
begin
  VarClear(FJson);
  inherited;
end;

function TgsJsonImplMormot.DVD : PDocVariantData;
begin
  if DocVariantType.IsOfType(FJson) then
    result := @TDocVariantData(FJson)
  else
    result := nil;
end;

procedure TgsJsonImplMormot.EnsureObj;
begin
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
  if not DocVariantType.IsOfType(FJson) or (TDocVariantData(FJson).Kind = dvArray) then begin
    TDocVariant.NewFast(FJson);
    TDocVariantData(FJson).Init(mFastFloat, dvObject);
  end;
end;

procedure TgsJsonImplMormot.EnsureArr;
begin
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
  if not DocVariantType.IsOfType(FJson) or (TDocVariantData(FJson).Kind <> dvArray) then begin
    TDocVariant.NewFast(FJson);
    TDocVariantData(FJson).Init(mFastFloat, dvArray);
  end;
end;

function TgsJsonImplMormot.parse(aJsonStr: string): igsJson;
var
  trimmed : string;
  c : char;
  u : RawUtf8;
begin
  result := self;
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';

  trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');

  c := trimmed[1];
  u := StringToUtf8(trimmed);

  if (c = '{') or (c = '[') then begin
    FJson := _JsonFast(u);
    if not DocVariantType.IsOfType(FJson) then
      raise JsonException.Create('JSON parse error: ' + aJsonStr);
  end
  else begin
    // Bare value
    if trimmed = 'null' then begin
      FBareType := TgsJsonElementType.etNull;
      FBareValue := 'null';
    end
    else if (trimmed = 'true') or (trimmed = 'false') then begin
      FBareType := TgsJsonElementType.etBoolean;
      FBareValue := LowerCase(trimmed);
    end
    else if c = '"' then begin
      FBareType := TgsJsonElementType.etString;
      FBareValue := Copy(trimmed, 2, Length(trimmed) - 2);
    end
    else begin
      FBareType := TgsJsonElementType.etNumber;
      FBareValue := trimmed;
    end;
  end;
end;

function TgsJsonImplMormot.put(name: string; val: double): igsJson;
begin
  result := self;
  EnsureObj;
  TDocVariantData(FJson).AddOrUpdateValue(StringToUtf8(name), variant(val));
end;

function TgsJsonImplMormot.put(name, val: string): igsJson;
begin
  result := self;
  EnsureObj;
  TDocVariantData(FJson).AddOrUpdateValue(StringToUtf8(name), variant(val));
end;

function TgsJsonImplMormot.put(name: string; val: boolean): igsJson;
begin
  result := self;
  EnsureObj;
  TDocVariantData(FJson).AddOrUpdateValue(StringToUtf8(name), variant(val));
end;

function TgsJsonImplMormot.put(vals: array of const): igsJson;
begin
  result := self;
  EnsureArr;
  AddArrayOfConst(@TDocVariantData(FJson), vals);
end;

function TgsJsonImplMormot.put(name: string; vals: array of const): igsJson;
var
  arr : variant;
begin
  result := self;
  EnsureObj;
  TDocVariant.NewFast(arr);
  TDocVariantData(arr).Init(mFastFloat, dvArray);
  AddArrayOfConst(@TDocVariantData(arr), vals);
  TDocVariantData(FJson).AddOrUpdateValue(StringToUtf8(name), arr);
end;

function TgsJsonImplMormot.put(name: string; val: igsJson): igsJson;
var
  childJson : RawUtf8;
  child : variant;
begin
  result := self;
  EnsureObj;
  childJson := StringToUtf8(val.stringify);
  child := _JsonFast(childJson);
  TDocVariantData(FJson).AddOrUpdateValue(StringToUtf8(name), child);
end;

function TgsJsonImplMormot.put(val: igsJson): igsJson;
var
  childJson : RawUtf8;
  child : variant;
begin
  result := self;
  EnsureArr;
  childJson := StringToUtf8(val.stringify);
  child := _JsonFast(childJson);
  TDocVariantData(FJson).AddItem(child);
end;

function TgsJsonImplMormot.stringify(var aStr: string): igsJson;
begin
  result := self;
  aStr := stringify;
end;

function TgsJsonImplMormot.stringify: string;
begin
  if FBareType <> TgsJsonElementType.etEmpty then begin
    case FBareType of
      TgsJsonElementType.etString : result := '"' + FBareValue + '"';
      TgsJsonElementType.etNull   : result := 'null';
    else
      result := FBareValue;
    end;
  end
  else if DocVariantType.IsOfType(FJson) then
    result := Utf8ToString(TDocVariantData(FJson).ToJson)
  else
    result := 'null';
end;

function TgsJsonImplMormot.get(name: string; var value: string): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if (p <> nil) and (p^.Kind = dvObject) then
    value := p^.S[StringToUtf8(name)]
  else
    raise JsonException.Create('TgsJsonImplMormot.get: Not an object');
end;

function TgsJsonImplMormot.get(index: integer; var value: string): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if p <> nil then
    value := VarToStr(p^.Values[index])
  else
    raise JsonException.Create('TgsJsonImplMormot.get: No data');
end;

function TgsJsonImplMormot.get(name: string; var value: integer): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if (p <> nil) and (p^.Kind = dvObject) then
    value := Integer(p^.I[StringToUtf8(name)])
  else
    raise JsonException.Create('TgsJsonImplMormot.get: Not an object');
end;

function TgsJsonImplMormot.get(index: integer; var value: integer): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if p <> nil then
    value := Integer(Int64(p^.Values[index]))
  else
    raise JsonException.Create('TgsJsonImplMormot.get: No data');
end;

function TgsJsonImplMormot.get(name: string; var value: Double): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if (p <> nil) and (p^.Kind = dvObject) then
    value := p^.D[StringToUtf8(name)]
  else
    raise JsonException.Create('TgsJsonImplMormot.get: Not an object');
end;

function TgsJsonImplMormot.get(index: integer; var value: Double): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if p <> nil then
    value := Double(p^.Values[index])
  else
    raise Exception.Create('TgsJsonImplMormot.get: No data');
end;

function TgsJsonImplMormot.get(name: string; var value: Boolean): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if (p <> nil) and (p^.Kind = dvObject) then
    value := p^.B[StringToUtf8(name)]
  else
    raise Exception.Create('TgsJsonImplMormot.get: Not an object');
end;

function TgsJsonImplMormot.get(index: integer; var value: Boolean): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if p <> nil then
    value := Boolean(p^.Values[index])
  else
    raise Exception.Create('TgsJsonImplMormot.get: No data');
end;

function TgsJsonImplMormot.get(name: string; var value: igsJson): igsJson;
var
  p : PDocVariantData;
  v : variant;
  idx : integer;
begin
  result := self;
  p := DVD;
  if (p <> nil) and (p^.Kind = dvObject) then begin
    idx := p^.GetValueIndex(StringToUtf8(name));
    if idx >= 0 then begin
      v := p^.Values[idx];
      ExtractMormotValue(v, value);
    end
    else
      raise Exception.Create('TgsJsonImplMormot.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplMormot.get: Not an object');
end;

function TgsJsonImplMormot.get(index: integer; var value: igsJson): igsJson;
var
  p : PDocVariantData;
begin
  result := self;
  p := DVD;
  if p <> nil then begin
    assert(index < p^.Count);
    ExtractMormotValue(p^.Values[index], value);
  end;
end;

function TgsJsonImplMormot.jsonElementCount: integer;
var
  p : PDocVariantData;
begin
  if FBareType <> TgsJsonElementType.etEmpty then
    result := -1
  else begin
    p := DVD;
    if p <> nil then
      result := p^.Count
    else
      result := -1;
  end;
end;

function TgsJsonImplMormot.jsonElementType(index: integer): TgsJsonElementType;
var
  p : PDocVariantData;
begin
  result := TgsJsonElementType.etEmpty;
  p := DVD;
  if (p <> nil) and (index >= 0) and (index < p^.Count) then
    result := VariantToElementType(p^.Values[index]);
end;

function TgsJsonImplMormot.jsonType: TgsJsonElementType;
var
  p : PDocVariantData;
begin
  if FBareType <> TgsJsonElementType.etEmpty then
    result := FBareType
  else begin
    p := DVD;
    if p <> nil then begin
      if p^.Kind = dvArray then
        result := TgsJsonElementType.etJsonArray
      else
        result := TgsJsonElementType.etJson;
    end
    else
      result := TgsJsonElementType.etEmpty;
  end;
end;

function TgsJsonImplMormot.jsonElementName(index: integer): string;
var
  p : PDocVariantData;
begin
  result := '';
  p := DVD;
  if (p <> nil) and (p^.Kind = dvObject) then begin
    assert(index < p^.Count);
    result := Utf8ToString(p^.Names[index]);
  end
  else
    raise Exception.Create('TgsJsonImplMormot.jsonElementName: Not an object');
end;

function TgsJsonImplMormot.clear: igsJson;
begin
  result := self;
  VarClear(FJson);
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
  FOwned := true;
end;

function TgsJsonImplMormot.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplMormot.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplMormot.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplMormot.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplMormot.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplMormot.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplMormot.add(val: igsJson): igsJson;
var
  childJson : RawUtf8;
  child : variant;
begin
  result := self;
  EnsureArr;
  childJson := StringToUtf8(val.stringify);
  child := _JsonFast(childJson);
  TDocVariantData(FJson).AddItem(child);
end;

function TgsJsonImplMormot.add(val: double): igsJson;
begin
  result := self;
  EnsureArr;
  TDocVariantData(FJson).AddItem(variant(val));
end;

function TgsJsonImplMormot.add(val: integer): igsJson;
begin
  result := self;
  EnsureArr;
  TDocVariantData(FJson).AddItem(variant(val));
end;

function TgsJsonImplMormot.add(val: string): igsJson;
begin
  result := self;
  EnsureArr;
  TDocVariantData(FJson).AddItem(variant(val));
end;

function TgsJsonImplMormot.add(val: byte): igsJson;
begin
  result := self;
  EnsureArr;
  TDocVariantData(FJson).AddItem(variant(Integer(val)));
end;

function TgsJsonImplMormot.add(val: boolean): igsJson;
begin
  result := self;
  EnsureArr;
  TDocVariantData(FJson).AddItem(variant(val));
end;

function TgsJsonImplMormot.isNameExists(name: String): boolean;
var
  p : PDocVariantData;
begin
  result := false;
  p := DVD;
  if (p <> nil) and (p^.Kind = dvObject) then
    result := p^.GetValueIndex(StringToUtf8(name)) >= 0;
end;

function TgsJsonImplMormot.ToObj: igsJson;
begin
  result := self;
  EnsureObj;
end;

function TgsJsonImplMormot.ToArray: igsJson;
begin
  result := self;
  EnsureArr;
end;

{ TgsJsonImplMormotFactory }

function TgsJsonImplMormotFactory.getAuthor: string;
begin
  result := 'Arnaud Bouchez / Synopse';
end;

function TgsJsonImplMormotFactory.getTitle: string;
begin
  result := 'mORMot2';
end;

function TgsJsonImplMormotFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplMormotFactory.getId: string;
begin
  result := 'mormot2';
end;

function TgsJsonImplMormotFactory.getJson: igsJson;
begin
  result := TgsJsonImplMormot.Create;
end;

initialization

addImplementation(TgsJsonImplMormotFactory.Create);

end.
