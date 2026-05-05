///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.beroJson;

interface

uses sysutils,
     classes,
     gs.Json,
     PasJSON;

type

TgsJsonImplBero = class(TInterfacedObject, igsJson)
private
protected
  FJson : TPasJSONItem;
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

TgsJsonImplBeroFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

function itemToElementType(aItem : TPasJSONItem) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aItem = nil then
    exit;
  case aItem.ItemType of
    TPasJSONItemType.Null : result := TgsJsonElementType.etNull;
    TPasJSONItemType.Boolean_ : result := TgsJsonElementType.etBoolean;
    TPasJSONItemType.Number : result := TgsJsonElementType.etNumber;
    TPasJSONItemType.String_ : result := TgsJsonElementType.etString;
    TPasJSONItemType.Object_ : result := TgsJsonElementType.etJson;
    TPasJSONItemType.Array_ : result := TgsJsonElementType.etJsonArray;
  end;
end;

procedure extractValue(source : TPasJSONItem; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplBero.Create;

  if TgsJsonImplBero(value).FOwned and (TgsJsonImplBero(value).FJson <> nil) then
    TgsJsonImplBero(value).FJson.Free;
  TgsJsonImplBero(value).FJson := source;
  TgsJsonImplBero(value).FOwned := false;
end;

function getAsObj(var FJson : TPasJSONItem; var FOwned : boolean) : TPasJSONItemObject;
begin
  if not (FJson is TPasJSONItemObject) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TPasJSONItemObject.Create;
    FOwned := true;
  end;
  result := TPasJSONItemObject(FJson);
end;

function getAsArr(var FJson : TPasJSONItem; var FOwned : boolean) : TPasJSONItemArray;
begin
  if not (FJson is TPasJSONItemArray) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TPasJSONItemArray.Create;
    FOwned := true;
  end;
  result := TPasJSONItemArray(FJson);
end;

procedure addToArray(arr : TPasJSONItemArray; const vals : array of const);
begin
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : arr.Add(TPasJSONItemString.Create(UTF8String(String(vals[i].VString^))));
      vtWideString : arr.Add(TPasJSONItemString.Create(UTF8String(String(vals[i].VWideString))));
      vtUnicodeString : arr.Add(TPasJSONItemString.Create(UTF8String(UnicodeString(vals[i].VUnicodeString))));
      vtInteger : arr.Add(TPasJSONItemNumber.Create(vals[i].VInteger));
      vtBoolean : arr.Add(TPasJSONItemBoolean.Create(vals[i].VBoolean));
      vtExtended : arr.Add(TPasJSONItemNumber.Create(vals[i].VExtended^));
    end;
  end;
end;

{ TgsJsonImplBero }

constructor TgsJsonImplBero.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplBero.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplBero.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FJson := TPasJSON.Parse(UTF8Encode(trimmed), []);
  if FJson = nil then
    raise Exception.Create('JSON parse error: ' + aJsonStr);
  FOwned := true;
end;

function TgsJsonImplBero.put(name: string; val: double): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var key := TPasJSONUTF8String(name);
  var idx := obj.Indices[key];
  if idx >= 0 then
    obj.Delete(idx);
  obj.Add(key, TPasJSONItemNumber.Create(val));
end;

function TgsJsonImplBero.put(name, val: string): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var key := TPasJSONUTF8String(name);
  var idx := obj.Indices[key];
  if idx >= 0 then
    obj.Delete(idx);
  obj.Add(key, TPasJSONItemString.Create(TPasJSONUTF8String(val)));
end;

function TgsJsonImplBero.put(name: string; val: boolean): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var key := TPasJSONUTF8String(name);
  var idx := obj.Indices[key];
  if idx >= 0 then
    obj.Delete(idx);
  obj.Add(key, TPasJSONItemBoolean.Create(val));
end;

function TgsJsonImplBero.put(vals: array of const): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  addToArray(arr, vals);
end;

function TgsJsonImplBero.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var key := TPasJSONUTF8String(name);
  var idx := obj.Indices[key];
  if idx >= 0 then
    obj.Delete(idx);
  var arr := TPasJSONItemArray.Create;
  addToArray(arr, vals);
  obj.Add(key, arr);
end;

function TgsJsonImplBero.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var key := TPasJSONUTF8String(name);
  var idx := obj.Indices[key];
  if idx >= 0 then
    obj.Delete(idx);
  var parsed := TPasJSON.Parse(UTF8Encode(val.stringify), []);
  if parsed <> nil then
    obj.Add(key, parsed);
end;

function TgsJsonImplBero.put(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := TPasJSON.Parse(UTF8Encode(val.stringify), []);
  if parsed <> nil then
    arr.Add(parsed);
end;

function TgsJsonImplBero.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := UTF8ToString(TPasJSON.Stringify(FJson, false, []))
  else
    aStr := 'null';
end;

function TgsJsonImplBero.stringify: string;
begin
  if FJson <> nil then
    result := UTF8ToString(TPasJSON.Stringify(FJson, false, []))
  else
    result := 'null';
end;

function TgsJsonImplBero.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    var v := TPasJSONItemObject(FJson).Properties[TPasJSONUTF8String(name)];
    if v <> nil then
      value := String(TPasJSON.GetString(v))
    else
      raise Exception.Create('TgsJsonImplBero.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplBero.get: Not an object');
end;

function TgsJsonImplBero.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    assert(index < TPasJSONItemObject(FJson).Count);
    value := String(TPasJSON.GetString(TPasJSONItemObject(FJson).Values[index]));
  end
  else if FJson is TPasJSONItemArray then begin
    assert(index < TPasJSONItemArray(FJson).Count);
    value := String(TPasJSON.GetString(TPasJSONItemArray(FJson).Items[index]));
  end;
end;

function TgsJsonImplBero.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    var v := TPasJSONItemObject(FJson).Properties[TPasJSONUTF8String(name)];
    value := Integer(TPasJSON.GetInt64(v));
  end
  else
    raise Exception.Create('TgsJsonImplBero.get: Not an object');
end;

function TgsJsonImplBero.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    assert(index < TPasJSONItemObject(FJson).Count);
    value := Integer(TPasJSON.GetInt64(TPasJSONItemObject(FJson).Values[index]));
  end
  else if FJson is TPasJSONItemArray then begin
    assert(index < TPasJSONItemArray(FJson).Count);
    value := Integer(TPasJSON.GetInt64(TPasJSONItemArray(FJson).Items[index]));
  end;
end;

function TgsJsonImplBero.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    var v := TPasJSONItemObject(FJson).Properties[TPasJSONUTF8String(name)];
    value := TPasJSON.GetNumber(v);
  end
  else
    raise Exception.Create('TgsJsonImplBero.get: Not an object');
end;

function TgsJsonImplBero.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    assert(index < TPasJSONItemObject(FJson).Count);
    value := TPasJSON.GetNumber(TPasJSONItemObject(FJson).Values[index]);
  end
  else if FJson is TPasJSONItemArray then begin
    assert(index < TPasJSONItemArray(FJson).Count);
    value := TPasJSON.GetNumber(TPasJSONItemArray(FJson).Items[index]);
  end;
end;

function TgsJsonImplBero.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    var v := TPasJSONItemObject(FJson).Properties[TPasJSONUTF8String(name)];
    value := TPasJSON.GetBoolean(v);
  end
  else
    raise Exception.Create('TgsJsonImplBero.get: Not an object');
end;

function TgsJsonImplBero.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    assert(index < TPasJSONItemObject(FJson).Count);
    value := TPasJSON.GetBoolean(TPasJSONItemObject(FJson).Values[index]);
  end
  else if FJson is TPasJSONItemArray then begin
    assert(index < TPasJSONItemArray(FJson).Count);
    value := TPasJSON.GetBoolean(TPasJSONItemArray(FJson).Items[index]);
  end;
end;

function TgsJsonImplBero.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    var v := TPasJSONItemObject(FJson).Properties[TPasJSONUTF8String(name)];
    if v <> nil then
      extractValue(v, value)
    else
      raise Exception.Create('TgsJsonImplBero.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplBero.get: Not an object');
end;

function TgsJsonImplBero.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TPasJSONItemObject then begin
    assert(index < TPasJSONItemObject(FJson).Count);
    extractValue(TPasJSONItemObject(FJson).Values[index], value);
  end
  else if FJson is TPasJSONItemArray then begin
    assert(index < TPasJSONItemArray(FJson).Count);
    extractValue(TPasJSONItemArray(FJson).Items[index], value);
  end;
end;

function TgsJsonImplBero.jsonElementCount: integer;
begin
  if FJson is TPasJSONItemObject then
    result := TPasJSONItemObject(FJson).Count
  else if FJson is TPasJSONItemArray then
    result := TPasJSONItemArray(FJson).Count
  else
    result := -1;
end;

function TgsJsonImplBero.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FJson is TPasJSONItemObject then
    result := itemToElementType(TPasJSONItemObject(FJson).Values[index])
  else if FJson is TPasJSONItemArray then
    result := itemToElementType(TPasJSONItemArray(FJson).Items[index]);
end;

function TgsJsonImplBero.jsonType: TgsJsonElementType;
begin
  result := itemToElementType(FJson);
end;

function TgsJsonImplBero.jsonElementName(index: integer): string;
begin
  result := '';
  if FJson is TPasJSONItemObject then begin
    assert(index < TPasJSONItemObject(FJson).Count);
    result := String(TPasJSONItemObject(FJson).Keys[index]);
  end
  else
    raise Exception.Create('TgsJsonImplBero.jsonElementName: Not an object');
end;

function TgsJsonImplBero.clear: igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplBero.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplBero.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplBero.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplBero.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplBero.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplBero.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplBero.add(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := TPasJSON.Parse(UTF8Encode(val.stringify), []);
  if parsed <> nil then
    arr.Add(parsed);
end;

function TgsJsonImplBero.add(val: double): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(TPasJSONItemNumber.Create(val));
end;

function TgsJsonImplBero.add(val: integer): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(TPasJSONItemNumber.Create(val));
end;

function TgsJsonImplBero.add(val: string): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(TPasJSONItemString.Create(TPasJSONUTF8String(val)));
end;

function TgsJsonImplBero.add(val: byte): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(TPasJSONItemNumber.Create(Integer(val)));
end;

function TgsJsonImplBero.add(val: boolean): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.Add(TPasJSONItemBoolean.Create(val));
end;

function TgsJsonImplBero.isNameExists(name: String): boolean;
begin
  result := false;
  if FJson is TPasJSONItemObject then
    result := TPasJSONItemObject(FJson).Indices[TPasJSONUTF8String(name)] >= 0;
end;

function TgsJsonImplBero.ToObj: igsJson;
begin
  result := self;
  if not (FJson is TPasJSONItemObject) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TPasJSONItemObject.Create;
    FOwned := true;
  end;
end;

function TgsJsonImplBero.ToArray: igsJson;
begin
  result := self;
  if not (FJson is TPasJSONItemArray) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TPasJSONItemArray.Create;
    FOwned := true;
  end;
end;

{ TgsJsonImplBeroFactory }

function TgsJsonImplBeroFactory.getAuthor: string;
begin
  result := 'Benjamin Rosseaux (BeRo1985)';
end;

function TgsJsonImplBeroFactory.getTitle: string;
begin
  result := 'PasJSON';
end;

function TgsJsonImplBeroFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplBeroFactory.getId: string;
begin
  result := 'berojson';
end;

function TgsJsonImplBeroFactory.getJson: igsJson;
begin
  result := TgsJsonImplBero.Create;
end;

initialization

addImplementation(TgsJsonImplBeroFactory.Create);

end.
