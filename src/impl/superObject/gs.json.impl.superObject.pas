///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.superObject;

interface

uses sysutils,
     classes,
     gs.Json,
     superobject, supertypes;

type

TgsJsonImplSuperObject = class(TInterfacedObject, igsJson)
private
protected
  FJson : ISuperObject;
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

TgsJsonImplSuperObjectFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

function superTypeToElementType(aObj : ISuperObject) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aObj = nil then
    exit;
  case aObj.DataType of
    stNull    : result := TgsJsonElementType.etNull;
    stBoolean : result := TgsJsonElementType.etBoolean;
    stDouble,
    stCurrency,
    stInt     : result := TgsJsonElementType.etNumber;
    stString  : result := TgsJsonElementType.etString;
    stObject  : result := TgsJsonElementType.etJson;
    stArray   : result := TgsJsonElementType.etJsonArray;
  end;
end;

procedure extractValue(source : ISuperObject; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplSuperObject.Create;

  TgsJsonImplSuperObject(value).FJson := source;
  TgsJsonImplSuperObject(value).FOwned := false;
end;

function getAsObj(var FJson : ISuperObject; var FOwned : boolean) : ISuperObject;
begin
  if (FJson = nil) or (FJson.DataType <> stObject) then begin
    FJson := TSuperObject.Create(stObject);
    FOwned := true;
  end;
  result := FJson;
end;

function getAsArr(var FJson : ISuperObject; var FOwned : boolean) : ISuperObject;
begin
  if (FJson = nil) or (FJson.DataType <> stArray) then begin
    FJson := TSuperObject.Create(stArray);
    FOwned := true;
  end;
  result := FJson;
end;

procedure addToArray(arr : ISuperObject; const vals : array of const);
begin
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString      : arr.AsArray.Add(TSuperObject.Create(SOString(String(vals[i].VString^))));
      vtWideString  : arr.AsArray.Add(TSuperObject.Create(SOString(PWideChar(vals[i].VWideString))));
      vtUnicodeString : arr.AsArray.Add(TSuperObject.Create(SOString(String(vals[i].VUnicodeString))));
      vtInteger     : arr.AsArray.Add(TSuperObject.Create(SuperInt(vals[i].VInteger)));
      vtBoolean     : arr.AsArray.Add(TSuperObject.Create(vals[i].VBoolean));
      vtExtended    : arr.AsArray.Add(TSuperObject.Create(vals[i].VExtended^));
    end;
  end;
end;

{ Helpers - get key name at index via iterator }

function getKeyNameAtIndex(obj : ISuperObject; index : integer) : SOString;
var
  iter : TSuperAvlIterator;
  entry : TSuperAvlEntry;
  i : integer;
begin
  result := '';
  iter := obj.AsObject.GetEnumerator;
  try
    iter.First;
    i := 0;
    entry := iter.GetIter;
    while entry <> nil do begin
      if i = index then begin
        result := entry.Name;
        exit;
      end;
      inc(i);
      iter.Next;
      entry := iter.GetIter;
    end;
  finally
    iter.Free;
  end;
end;

function getValueAtIndex(obj : ISuperObject; index : integer) : ISuperObject;
var
  iter : TSuperAvlIterator;
  entry : TSuperAvlEntry;
  i : integer;
begin
  result := nil;
  iter := obj.AsObject.GetEnumerator;
  try
    iter.First;
    i := 0;
    entry := iter.GetIter;
    while entry <> nil do begin
      if i = index then begin
        result := entry.Value;
        exit;
      end;
      inc(i);
      iter.Next;
      entry := iter.GetIter;
    end;
  finally
    iter.Free;
  end;
end;

{ TgsJsonImplSuperObject }

constructor TgsJsonImplSuperObject.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplSuperObject.Destroy;
begin
  FJson := nil; // ISuperObject is ref-counted, just release
  inherited;
end;

function TgsJsonImplSuperObject.parse(aJsonStr: string): igsJson;
begin
  result := self;
  FJson := nil;
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FJson := SO(trimmed);
  if FJson = nil then
    raise JsonException.Create('JSON parse error: ' + aJsonStr);
  FOwned := true;
end;

function TgsJsonImplSuperObject.put(name: string; val: double): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  obj.D[SOString(name)] := val;
end;

function TgsJsonImplSuperObject.put(name, val: string): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  obj.S[SOString(name)] := SOString(val);
end;

function TgsJsonImplSuperObject.put(name: string; val: boolean): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  obj.B[SOString(name)] := val;
end;

function TgsJsonImplSuperObject.put(vals: array of const): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  addToArray(arr, vals);
end;

function TgsJsonImplSuperObject.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var arr : ISuperObject := TSuperObject.Create(stArray);
  addToArray(arr, vals);
  obj.O[SOString(name)] := arr;
end;

function TgsJsonImplSuperObject.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var parsed := SO(val.stringify);
  if parsed <> nil then
    obj.O[SOString(name)] := parsed;
end;

function TgsJsonImplSuperObject.put(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := SO(val.stringify);
  if parsed <> nil then
    arr.AsArray.Add(parsed);
end;

function TgsJsonImplSuperObject.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := String(FJson.AsJSon(false, false))
  else
    aStr := 'null';
end;

function TgsJsonImplSuperObject.stringify: string;
begin
  if FJson <> nil then
    result := String(FJson.AsJSon(false, false))
  else
    result := 'null';
end;

function TgsJsonImplSuperObject.get(name: string; var value: string): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    var v := FJson.O[SOString(name)];
    if v <> nil then
      value := String(v.AsString)
    else
      raise JsonException.Create('TgsJsonImplSuperObject.get: Key not found: ' + name);
  end
  else
    raise JsonException.Create('TgsJsonImplSuperObject.get: Not an object');
end;

function TgsJsonImplSuperObject.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    assert(index < FJson.AsObject.count);
    var v := getValueAtIndex(FJson, index);
    if v <> nil then
      value := String(v.AsString)
    else
      value := '';
  end
  else if (FJson <> nil) and (FJson.DataType = stArray) then begin
    assert(index < FJson.AsArray.Length);
    value := String(FJson.AsArray.S[index]);
  end;
end;

function TgsJsonImplSuperObject.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    value := Integer(FJson.I[SOString(name)]);
  end
  else
    raise JsonException.Create('TgsJsonImplSuperObject.get: Not an object');
end;

function TgsJsonImplSuperObject.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    assert(index < FJson.AsObject.count);
    var v := getValueAtIndex(FJson, index);
    if v <> nil then
      value := Integer(v.AsInteger)
    else
      value := 0;
  end
  else if (FJson <> nil) and (FJson.DataType = stArray) then begin
    assert(index < FJson.AsArray.Length);
    value := Integer(FJson.AsArray.I[index]);
  end;
end;

function TgsJsonImplSuperObject.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    value := FJson.D[SOString(name)];
  end
  else
    raise JsonException.Create('TgsJsonImplSuperObject.get: Not an object');
end;

function TgsJsonImplSuperObject.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    assert(index < FJson.AsObject.count);
    var v := getValueAtIndex(FJson, index);
    if v <> nil then
      value := v.AsDouble
    else
      value := 0.0;
  end
  else if (FJson <> nil) and (FJson.DataType = stArray) then begin
    assert(index < FJson.AsArray.Length);
    value := FJson.AsArray.D[index];
  end;
end;

function TgsJsonImplSuperObject.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    value := FJson.B[SOString(name)];
  end
  else
    raise JsonException.Create('TgsJsonImplSuperObject.get: Not an object');
end;

function TgsJsonImplSuperObject.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    assert(index < FJson.AsObject.count);
    var v := getValueAtIndex(FJson, index);
    if v <> nil then
      value := v.AsBoolean
    else
      value := false;
  end
  else if (FJson <> nil) and (FJson.DataType = stArray) then begin
    assert(index < FJson.AsArray.Length);
    value := FJson.AsArray.B[index];
  end;
end;

function TgsJsonImplSuperObject.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    var v := FJson.O[SOString(name)];
    if v <> nil then
      extractValue(v, value)
    else
      raise JsonException.Create('TgsJsonImplSuperObject.get: Key not found: ' + name);
  end
  else
    raise JsonException.Create('TgsJsonImplSuperObject.get: Not an object');
end;

function TgsJsonImplSuperObject.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    assert(index < FJson.AsObject.count);
    var v := getValueAtIndex(FJson, index);
    extractValue(v, value);
  end
  else if (FJson <> nil) and (FJson.DataType = stArray) then begin
    assert(index < FJson.AsArray.Length);
    extractValue(FJson.AsArray.O[index], value);
  end;
end;

function TgsJsonImplSuperObject.jsonElementCount: integer;
begin
  if (FJson <> nil) and (FJson.DataType = stObject) then
    result := FJson.AsObject.count
  else if (FJson <> nil) and (FJson.DataType = stArray) then
    result := FJson.AsArray.Length
  else
    result := -1;
end;

function TgsJsonImplSuperObject.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if (FJson <> nil) and (FJson.DataType = stObject) then
    result := superTypeToElementType(getValueAtIndex(FJson, index))
  else if (FJson <> nil) and (FJson.DataType = stArray) then
    result := superTypeToElementType(FJson.AsArray.O[index]);
end;

function TgsJsonImplSuperObject.jsonType: TgsJsonElementType;
begin
  result := superTypeToElementType(FJson);
end;

function TgsJsonImplSuperObject.jsonElementName(index: integer): string;
begin
  result := '';
  if (FJson <> nil) and (FJson.DataType = stObject) then begin
    assert(index < FJson.AsObject.count);
    result := String(getKeyNameAtIndex(FJson, index));
  end
  else
    raise JsonException.Create('TgsJsonImplSuperObject.jsonElementName: Not an object');
end;

function TgsJsonImplSuperObject.clear: igsJson;
begin
  result := self;
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplSuperObject.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplSuperObject.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplSuperObject.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplSuperObject.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplSuperObject.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplSuperObject.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplSuperObject.add(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  var parsed := SO(val.stringify);
  if parsed <> nil then
    arr.AsArray.Add(parsed);
end;

function TgsJsonImplSuperObject.add(val: double): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AsArray.Add(TSuperObject.Create(val));
end;

function TgsJsonImplSuperObject.add(val: integer): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AsArray.Add(TSuperObject.Create(SuperInt(val)));
end;

function TgsJsonImplSuperObject.add(val: string): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AsArray.Add(TSuperObject.Create(SOString(val)));
end;

function TgsJsonImplSuperObject.add(val: byte): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AsArray.Add(TSuperObject.Create(SuperInt(val)));
end;

function TgsJsonImplSuperObject.add(val: boolean): igsJson;
begin
  result := self;
  var arr := getAsArr(FJson, FOwned);
  arr.AsArray.Add(TSuperObject.Create(val));
end;

function TgsJsonImplSuperObject.isNameExists(name: String): boolean;
begin
  result := false;
  if (FJson <> nil) and (FJson.DataType = stObject) then
    result := FJson.AsObject.Exists(SOString(name));
end;

function TgsJsonImplSuperObject.ToObj: igsJson;
begin
  result := self;
  if (FJson = nil) or (FJson.DataType <> stObject) then begin
    FJson := TSuperObject.Create(stObject);
    FOwned := true;
  end;
end;

function TgsJsonImplSuperObject.ToArray: igsJson;
begin
  result := self;
  if (FJson = nil) or (FJson.DataType <> stArray) then begin
    FJson := TSuperObject.Create(stArray);
    FOwned := true;
  end;
end;

{ TgsJsonImplSuperObjectFactory }

function TgsJsonImplSuperObjectFactory.getAuthor: string;
begin
  result := 'Henri Gourvest (hgourvest)';
end;

function TgsJsonImplSuperObjectFactory.getTitle: string;
begin
  result := 'SuperObject';
end;

function TgsJsonImplSuperObjectFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplSuperObjectFactory.getId: string;
begin
  result := 'superobject';
end;

function TgsJsonImplSuperObjectFactory.getJson: igsJson;
begin
  result := TgsJsonImplSuperObject.Create;
end;

initialization

addImplementation(TgsJsonImplSuperObjectFactory.Create);

end.
