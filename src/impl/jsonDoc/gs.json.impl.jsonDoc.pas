///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.jsonDoc;

interface

uses sysutils,
     classes,
     gs.Json,
     jsonDoc;

type

TgsJsonImplJsonDoc = class(TInterfacedObject, igsJson)
private
protected
  FDoc : IJSONDocument;
  FOwned : boolean;
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

TgsJsonImplJsonDocFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

uses Variants;

function variantToElementType(const v : Variant) : TgsJsonElementType;
var d: IJSONDocument;
    a: IJSONArray;
begin
  result := TgsJsonElementType.etEmpty;
  if VarIsNull(v) or VarIsEmpty(v) then
    result := TgsJsonElementType.etEmpty
  else if VarIsStr(v) then
    result := TgsJsonElementType.etString
  else if VarIsType(v, varBoolean) then
    result := TgsJsonElementType.etBoolean
  else if VarIsNumeric(v) then
    result := TgsJsonElementType.etNumber
  else if VarIsArray(v) then
    result := TgsJsonElementType.etJsonArray
  else if isJSON(v, d) then
    result := TgsJsonElementType.etJson
  else if isJSONArray(v, a) then
    result := TgsJsonElementType.etJsonArray;
end;

procedure extractValue(const source : Variant; var value : igsJson);
var d: IJSONDocument;
begin
  if not assigned(value) then
    value := TgsJsonImplJsonDoc.Create;

  if isJSON(source, d) then begin
    TgsJsonImplJsonDoc(value).FDoc := d;
  end else begin
    TgsJsonImplJsonDoc(value).FDoc := JSON;
    TgsJsonImplJsonDoc(value).FDoc['_v'] := source;
  end;
  TgsJsonImplJsonDoc(value).FOwned := false;
end;

procedure getValueByIndex(const doc: IJSONDocument; index: integer;
  out key: WideString; out val: Variant);
var e: IJSONEnumerator;
    i: integer;
begin
  key := '';
  val := Null;
  e := JSONEnum(doc);
  i := 0;
  while e.Next do begin
    if i = index then begin
      key := e.Key;
      val := e.Value;
      exit;
    end;
    inc(i);
  end;
end;

{ TgsJsonImplJsonDoc }

constructor TgsJsonImplJsonDoc.Create;
begin
  FDoc := nil;
  FOwned := true;
end;

destructor TgsJsonImplJsonDoc.Destroy;
begin
  FDoc := nil;
  inherited;
end;

function TgsJsonImplJsonDoc.parse(aJsonStr: string): igsJson;
begin
  result := self;
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FDoc := JSON;
  FDoc.Parse(trimmed);
  FOwned := true;
end;

function TgsJsonImplJsonDoc.put(name: string; val: double): igsJson;
begin
  result := self;
  if FDoc = nil then begin
    FDoc := JSON;
    FOwned := true;
  end;
  FDoc[name] := val;
end;

function TgsJsonImplJsonDoc.put(name, val: string): igsJson;
begin
  result := self;
  if FDoc = nil then begin
    FDoc := JSON;
    FOwned := true;
  end;
  FDoc[name] := val;
end;

function TgsJsonImplJsonDoc.put(name: string; val: boolean): igsJson;
begin
  result := self;
  if FDoc = nil then begin
    FDoc := JSON;
    FOwned := true;
  end;
  FDoc[name] := val;
end;

function TgsJsonImplJsonDoc.put(vals: array of const): igsJson;
begin
  result := self;
  raise JsonException.Create('TgsJsonImplJsonDoc: root-level array not supported');
end;

function TgsJsonImplJsonDoc.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  if FDoc = nil then begin
    FDoc := JSON;
    FOwned := true;
  end;
  var a : array of Variant;
  SetLength(a, Length(vals));
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : a[i] := String(vals[i].VString^);
      vtWideString : a[i] := WideString(vals[i].VWideString);
      vtUnicodeString : a[i] := UnicodeString(vals[i].VUnicodeString);
      vtInteger : a[i] := vals[i].VInteger;
      vtBoolean : a[i] := vals[i].VBoolean;
      vtExtended : a[i] := vals[i].VExtended^;
    end;
  end;
  FDoc[name] := ja(a);
end;

function TgsJsonImplJsonDoc.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  if FDoc = nil then begin
    FDoc := JSON;
    FOwned := true;
  end;
  var sub := JSON;
  sub.Parse(val.stringify);
  FDoc[name] := sub;
end;

function TgsJsonImplJsonDoc.put(val: igsJson): igsJson;
begin
  result := self;
  raise Exception.Create('TgsJsonImplJsonDoc: root-level array add not supported');
end;

function TgsJsonImplJsonDoc.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FDoc <> nil then
    aStr := FDoc.AsString
  else
    aStr := 'null';
end;

function TgsJsonImplJsonDoc.stringify: string;
begin
  if FDoc <> nil then
    result := FDoc.AsString
  else
    result := 'null';
end;

function TgsJsonImplJsonDoc.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FDoc <> nil then begin
    var v := FDoc[name];
    if VarIsNull(v) then
      raise Exception.Create('TgsJsonImplJsonDoc.get: Key not found: ' + name);
    value := VarToStr(v);
  end
  else
    raise Exception.Create('TgsJsonImplJsonDoc.get: Not an object');
end;

function TgsJsonImplJsonDoc.get(index: integer; var value: string): igsJson;
var k: WideString;
    v: Variant;
begin
  result := self;
  if FDoc <> nil then begin
    getValueByIndex(FDoc, index, k, v);
    if VarIsNull(v) and (k = '') then
      raise Exception.Create('TgsJsonImplJsonDoc.get: Index out of bounds');
    value := VarToStr(v);
  end;
end;

function TgsJsonImplJsonDoc.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FDoc <> nil then begin
    var v := FDoc[name];
    if VarIsNull(v) then
      raise Exception.Create('TgsJsonImplJsonDoc.get: Key not found: ' + name);
    value := v;
  end
  else
    raise Exception.Create('TgsJsonImplJsonDoc.get: Not an object');
end;

function TgsJsonImplJsonDoc.get(index: integer; var value: integer): igsJson;
var k: WideString;
    v: Variant;
    a: IJSONArray;
begin
  result := self;
  if FDoc <> nil then begin
    // Check if the stored value at first key is an array (for sub-array access)
    getValueByIndex(FDoc, index, k, v);
    if not VarIsNull(v) then
      value := v
    else
      raise JsonException.Create('TgsJsonImplJsonDoc.get: Index out of bounds');
  end;
end;

function TgsJsonImplJsonDoc.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FDoc <> nil then begin
    var v := FDoc[name];
    if VarIsNull(v) then
      raise JsonException.Create('TgsJsonImplJsonDoc.get: Key not found: ' + name);
    value := v;
  end
  else
    raise JsonException.Create('TgsJsonImplJsonDoc.get: Not an object');
end;

function TgsJsonImplJsonDoc.get(index: integer; var value: Double): igsJson;
var k: WideString;
    v: Variant;
begin
  result := self;
  if FDoc <> nil then begin
    getValueByIndex(FDoc, index, k, v);
    if not VarIsNull(v) then
      value := v
    else
      raise JsonException.Create('TgsJsonImplJsonDoc.get: Index out of bounds');
  end;
end;

function TgsJsonImplJsonDoc.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FDoc <> nil then begin
    var v := FDoc[name];
    if VarIsNull(v) then
      raise Exception.Create('TgsJsonImplJsonDoc.get: Key not found: ' + name);
    value := v;
  end
  else
    raise JsonException.Create('TgsJsonImplJsonDoc.get: Not an object');
end;

function TgsJsonImplJsonDoc.get(index: integer; var value: Boolean): igsJson;
var k: WideString;
    v: Variant;
begin
  result := self;
  if FDoc <> nil then begin
    getValueByIndex(FDoc, index, k, v);
    if not VarIsNull(v) then
      value := v
    else
      raise JsonException.Create('TgsJsonImplJsonDoc.get: Index out of bounds');
  end;
end;

function TgsJsonImplJsonDoc.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FDoc <> nil then begin
    var v := FDoc[name];
    if VarIsNull(v) then
      raise Exception.Create('TgsJsonImplJsonDoc.get: Key not found: ' + name);
    extractValue(v, value);
  end
  else
    raise JsonException.Create('TgsJsonImplJsonDoc.get: Not an object');
end;

function TgsJsonImplJsonDoc.get(index: integer; var value: igsJson): igsJson;
var k: WideString;
    v: Variant;
begin
  result := self;
  if FDoc <> nil then begin
    getValueByIndex(FDoc, index, k, v);
    extractValue(v, value);
  end;
end;

function TgsJsonImplJsonDoc.jsonElementCount: integer;
var e: IJSONEnumerator;
begin
  result := -1;
  if FDoc <> nil then begin
    result := 0;
    e := JSONEnum(FDoc);
    while e.Next do inc(result);
  end;
end;

function TgsJsonImplJsonDoc.jsonElementType(index: integer): TgsJsonElementType;
var k: WideString;
    v: Variant;
begin
  result := TgsJsonElementType.etEmpty;
  if FDoc <> nil then begin
    getValueByIndex(FDoc, index, k, v);
    result := variantToElementType(v);
  end;
end;

function TgsJsonImplJsonDoc.jsonType: TgsJsonElementType;
begin
  if FDoc <> nil then
    result := TgsJsonElementType.etJson
  else
    result := TgsJsonElementType.etEmpty;
end;

function TgsJsonImplJsonDoc.jsonElementName(index: integer): string;
var k: WideString;
    v: Variant;
begin
  result := '';
  if FDoc <> nil then begin
    getValueByIndex(FDoc, index, k, v);
    result := k;
  end;
end;

function TgsJsonImplJsonDoc.clear: igsJson;
begin
  result := self;
  FDoc := nil;
  FOwned := true;
end;

function TgsJsonImplJsonDoc.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplJsonDoc.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplJsonDoc.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplJsonDoc.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplJsonDoc.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplJsonDoc.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplJsonDoc.add(val: igsJson): igsJson;
begin
  result := self;
  raise JsonException.Create('TgsJsonImplJsonDoc: array add not supported');
end;

function TgsJsonImplJsonDoc.add(val: double): igsJson;
begin
  result := self;
  raise JsonException.Create('TgsJsonImplJsonDoc: array add not supported');
end;

function TgsJsonImplJsonDoc.add(val: integer): igsJson;
begin
  result := self;
  raise JsonException.Create('TgsJsonImplJsonDoc: array add not supported');
end;

function TgsJsonImplJsonDoc.add(val: string): igsJson;
begin
  result := self;
  raise JsonException.Create('TgsJsonImplJsonDoc: array add not supported');
end;

function TgsJsonImplJsonDoc.add(val: byte): igsJson;
begin
  result := self;
  raise JsonException.Create('TgsJsonImplJsonDoc: array add not supported');
end;

function TgsJsonImplJsonDoc.add(val: boolean): igsJson;
begin
  result := self;
  raise JsonException.Create('TgsJsonImplJsonDoc: array add not supported');
end;

function TgsJsonImplJsonDoc.isNameExists(name: String): boolean;
begin
  result := false;
  if FDoc <> nil then
    result := not VarIsNull(FDoc[name]);
end;

function TgsJsonImplJsonDoc.ToObj: igsJson;
begin
  result := self;
  if FDoc = nil then begin
    FDoc := JSON;
    FOwned := true;
  end;
end;

function TgsJsonImplJsonDoc.ToArray: igsJson;
begin
  result := self;
  raise Exception.Create('TgsJsonImplJsonDoc: ToArray not supported');
end;

{ TgsJsonImplJsonDocFactory }

function TgsJsonImplJsonDocFactory.getAuthor: string;
begin
  result := 'Stijn Sanders';
end;

function TgsJsonImplJsonDocFactory.getTitle: string;
begin
  result := 'jsonDoc';
end;

function TgsJsonImplJsonDocFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplJsonDocFactory.getId: string;
begin
  result := 'jsondoc';
end;

function TgsJsonImplJsonDocFactory.getJson: igsJson;
begin
  result := TgsJsonImplJsonDoc.Create;
end;

initialization

addImplementation(TgsJsonImplJsonDocFactory.Create);

end.
