///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.delphiJson;

interface

uses sysutils,
     classes,
     gs.Json,
     System.JSON;

type

TgsJsonImplDelphi = class(TInterfacedObject, igsJson)
private
protected
  FJson : TJSONValue;
  FOwned : boolean;
public
  constructor Create; virtual;
  destructor Destroy; override;

  function parse(aJsonStr : string) : igsJson;
  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;

  //Array
  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;

  //Add an object.
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

  //Object / Array
  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  //Analyses.
  function jsonElementCount : integer;
  function jsonElementType(index : integer) : TgsJsonElementType;
  function jsonType : TgsJsonElementType;
  function jsonElementName(index : integer) : string;

  function clear : igsJson;

  //Base type easy access.
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

TgsJsonImplDelphiFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

function jsonValueToElementType(aValue : TJSONValue) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aValue = nil then
    exit;
  if aValue is TJSONObject then
    result := TgsJsonElementType.etJson
  else if aValue is TJSONArray then
    result := TgsJsonElementType.etJsonArray
  //TJSONNumber inherits from TJSONString : check Number BEFORE String.
  else if aValue is TJSONNumber then
    result := TgsJsonElementType.etNumber
  else if aValue is TJSONString then
    result := TgsJsonElementType.etString
  else if aValue is TJSONBool then
    result := TgsJsonElementType.etBoolean
  else if aValue is TJSONNull then
    result := TgsJsonElementType.etNull;
end;

procedure extractValue(source : TJSONValue; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplDelphi.Create;

  if TgsJsonImplDelphi(value).FOwned and (TgsJsonImplDelphi(value).FJson <> nil) then
    TgsJsonImplDelphi(value).FJson.Free;
  TgsJsonImplDelphi(value).FJson := source;
  TgsJsonImplDelphi(value).FOwned := false;
end;

function getAsObj(var FJson : TJSONValue; var FOwned : boolean) : TJSONObject;
begin
  if not (FJson is TJSONObject) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TJSONObject.Create;
    FOwned := true;
  end;
  result := TJSONObject(FJson);
end;

function getAsArr(var FJson : TJSONValue; var FOwned : boolean) : TJSONArray;
begin
  if not (FJson is TJSONArray) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TJSONArray.Create;
    FOwned := true;
  end;
  result := TJSONArray(FJson);
end;

{ TgsJsonImplDelphi }

constructor TgsJsonImplDelphi.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplDelphi.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplDelphi.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FJson := TJSONObject.ParseJSONValue(trimmed);
  if FJson = nil then
    raise JsonException.Create('JSON parse error: ' + aJsonStr);
  FOwned := true;
end;

function TgsJsonImplDelphi.put(name: string; val: double): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var lp := obj.RemovePair(name);
  if lp <> nil then lp.Free;
  obj.AddPair(name, TJSONNumber.Create(val));
end;

function TgsJsonImplDelphi.put(name, val: string): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var lp := obj.RemovePair(name);
  if lp <> nil then lp.Free;
  obj.AddPair(name, val);
end;

function TgsJsonImplDelphi.put(name: string; val: boolean): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var lp := obj.RemovePair(name);
  if lp <> nil then lp.Free;
  if val then
    obj.AddPair(name, TJSONTrue.Create)
  else
    obj.AddPair(name, TJSONFalse.Create);
end;

function TgsJsonImplDelphi.put(vals: array of const): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : arr.AddElement(TJSONString.Create(String(vals[i].VString^)));
      vtWideString : arr.AddElement(TJSONString.Create(String(vals[i].VWideString)));
      vtUnicodeString : arr.AddElement(TJSONString.Create(UnicodeString(vals[i].VUnicodeString)));
      vtInteger : arr.AddElement(TJSONNumber.Create(vals[i].VInteger));
      vtBoolean : if vals[i].VBoolean then arr.AddElement(TJSONTrue.Create) else arr.AddElement(TJSONFalse.Create);
      vtExtended : arr.AddElement(TJSONNumber.Create(vals[i].VExtended^));
    end;
  end;
end;

function TgsJsonImplDelphi.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var arr := TJSONArray.Create;
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : arr.AddElement(TJSONString.Create(String(vals[i].VString^)));
      vtWideString : arr.AddElement(TJSONString.Create(String(vals[i].VWideString)));
      vtUnicodeString : arr.AddElement(TJSONString.Create(UnicodeString(vals[i].VUnicodeString)));
      vtInteger : arr.AddElement(TJSONNumber.Create(vals[i].VInteger));
      vtBoolean : if vals[i].VBoolean then arr.AddElement(TJSONTrue.Create) else arr.AddElement(TJSONFalse.Create);
      vtExtended : arr.AddElement(TJSONNumber.Create(vals[i].VExtended^));
    end;
  end;
  var lp := obj.RemovePair(name);
  if lp <> nil then lp.Free;
  obj.AddPair(name, arr);
end;

function TgsJsonImplDelphi.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var lp := obj.RemovePair(name);
  if lp <> nil then lp.Free;
  var parsed := TJSONObject.ParseJSONValue(val.stringify);
  if parsed <> nil then
    obj.AddPair(name, parsed);
end;

function TgsJsonImplDelphi.put(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := TJSONObject.ParseJSONValue(val.stringify);
  if parsed <> nil then
    arr.AddElement(parsed);
end;

function TgsJsonImplDelphi.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := FJson.ToJSON
  else
    aStr := 'null';
end;

function TgsJsonImplDelphi.stringify: string;
begin
  if FJson <> nil then
    result := FJson.ToJSON
  else
    result := 'null';
end;

function TgsJsonImplDelphi.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var v := TJSONObject(FJson).GetValue(name);
    if v <> nil then
      value := v.Value
    else
      raise Exception.Create('TgsJsonImplDelphi.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDelphi.get: Not an object');
end;

function TgsJsonImplDelphi.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    assert(index < TJSONObject(FJson).Count);
    value := TJSONObject(FJson).Pairs[index].JsonValue.Value;
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).Count);
    value := TJSONArray(FJson).Items[index].Value;
  end;
end;

function TgsJsonImplDelphi.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var v := TJSONObject(FJson).GetValue(name);
    value := (v as TJSONNumber).AsInt;
  end
  else
    raise Exception.Create('TgsJsonImplDelphi.get: Not an object');
end;

function TgsJsonImplDelphi.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    assert(index < TJSONObject(FJson).Count);
    value := (TJSONObject(FJson).Pairs[index].JsonValue as TJSONNumber).AsInt;
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).Count);
    value := (TJSONArray(FJson).Items[index] as TJSONNumber).AsInt;
  end;
end;

function TgsJsonImplDelphi.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var v := TJSONObject(FJson).GetValue(name);
    value := (v as TJSONNumber).AsDouble;
  end
  else
    raise Exception.Create('TgsJsonImplDelphi.get: Not an object');
end;

function TgsJsonImplDelphi.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    assert(index < TJSONObject(FJson).Count);
    value := (TJSONObject(FJson).Pairs[index].JsonValue as TJSONNumber).AsDouble;
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).Count);
    value := (TJSONArray(FJson).Items[index] as TJSONNumber).AsDouble;
  end;
end;

function TgsJsonImplDelphi.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var v := TJSONObject(FJson).GetValue(name);
    value := SameText(v.Value, 'true');
  end
  else
    raise Exception.Create('TgsJsonImplDelphi.get: Not an object');
end;

function TgsJsonImplDelphi.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    assert(index < TJSONObject(FJson).Count);
    value := SameText(TJSONObject(FJson).Pairs[index].JsonValue.Value, 'true');
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).Count);
    value := SameText(TJSONArray(FJson).Items[index].Value, 'true');
  end;
end;

function TgsJsonImplDelphi.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    var v := TJSONObject(FJson).GetValue(name);
    if v <> nil then
      extractValue(v, value)
    else
      raise Exception.Create('TgsJsonImplDelphi.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDelphi.get: Not an object');
end;

function TgsJsonImplDelphi.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TJSONObject then begin
    assert(index < TJSONObject(FJson).Count);
    extractValue(TJSONObject(FJson).Pairs[index].JsonValue, value);
  end
  else if FJson is TJSONArray then begin
    assert(index < TJSONArray(FJson).Count);
    extractValue(TJSONArray(FJson).Items[index], value);
  end;
end;

function TgsJsonImplDelphi.jsonElementCount: integer;
begin
  if FJson is TJSONObject then
    result := TJSONObject(FJson).Count
  else if FJson is TJSONArray then
    result := TJSONArray(FJson).Count
  else
    result := -1;
end;

function TgsJsonImplDelphi.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FJson is TJSONObject then
    result := jsonValueToElementType(TJSONObject(FJson).Pairs[index].JsonValue)
  else if FJson is TJSONArray then
    result := jsonValueToElementType(TJSONArray(FJson).Items[index]);
end;

function TgsJsonImplDelphi.jsonType: TgsJsonElementType;
begin
  result := jsonValueToElementType(FJson);
end;

function TgsJsonImplDelphi.jsonElementName(index: integer): string;
begin
  result := '';
  if FJson is TJSONObject then begin
    assert(index < TJSONObject(FJson).Count);
    result := TJSONObject(FJson).Pairs[index].JsonString.Value;
  end
  else
    raise Exception.Create('TgsJsonImplDelphi.jsonElementName: Not an object');
end;

function TgsJsonImplDelphi.clear: igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplDelphi.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplDelphi.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplDelphi.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplDelphi.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplDelphi.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplDelphi.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplDelphi.add(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := TJSONObject.ParseJSONValue(val.stringify);
  if parsed <> nil then
    arr.AddElement(parsed);
end;

function TgsJsonImplDelphi.add(val: double): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AddElement(TJSONNumber.Create(val));
end;

function TgsJsonImplDelphi.add(val: integer): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AddElement(TJSONNumber.Create(val));
end;

function TgsJsonImplDelphi.add(val: string): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AddElement(TJSONString.Create(val));
end;

function TgsJsonImplDelphi.add(val: byte): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AddElement(TJSONNumber.Create(Integer(val)));
end;

function TgsJsonImplDelphi.add(val: boolean): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  if val then
    arr.AddElement(TJSONTrue.Create)
  else
    arr.AddElement(TJSONFalse.Create);
end;

function TgsJsonImplDelphi.isNameExists(name: String): boolean;
begin
  result := false;
  if FJson is TJSONObject then
    result := TJSONObject(FJson).GetValue(name) <> nil;
end;

function TgsJsonImplDelphi.ToObj: igsJson;
begin
  result := self;
  if not (FJson is TJSONObject) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TJSONObject.Create;
    FOwned := true;
  end;
end;

function TgsJsonImplDelphi.ToArray: igsJson;
begin
  result := self;
  if not (FJson is TJSONArray) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TJSONArray.Create;
    FOwned := true;
  end;
end;

{ TgsJsonImplDelphiFactory }

function TgsJsonImplDelphiFactory.getAuthor: string;
begin
  result := '';
end;

function TgsJsonImplDelphiFactory.getTitle: string;
begin
  result := 'Delphi System.JSON';
end;

function TgsJsonImplDelphiFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplDelphiFactory.getId: string;
begin
  result := 'embarcaderoDelphiJson';
end;

function TgsJsonImplDelphiFactory.getJson: igsJson;
begin
  result := TgsJsonImplDelphi.Create;
end;

initialization

addImplementation(TgsJsonImplDelphiFactory.Create);

end.
