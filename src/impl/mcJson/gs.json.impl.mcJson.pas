///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.mcJson;

interface

uses sysutils,
     classes,
     gs.Json,
     mcJson;

type

TgsJsonImplMc = class(TInterfacedObject, igsJson)
private
protected
  FJson  : TMcJsonItem;
  FOwned : boolean;
public
  constructor Create; virtual;
  destructor Destroy; override;

  function parse(aJsonStr : string) : igsJson;
  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;

  // Array
  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;

  // Add an object.
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

  // Object / Array
  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  // Analyses.
  function jsonElementCount : integer;
  function jsonElementType(index : integer) : TgsJsonElementType;
  function jsonType : TgsJsonElementType;
  function jsonElementName(index : integer) : string;

  function clear : igsJson;

  // Base type easy access.
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

  function isNameExists(name : String) : boolean;

  function ToObj : igsJson;
  function ToArray : igsJson;
end;

TgsJsonImplMcFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

// ---------------------------------------------------------------------------
// Helper : TMcJsonItem -> TgsJsonElementType (for a single item/value node)
// ValType (fValType) is private in McJSON — we detect the scalar sub-type via
// the public GetValueStr helper which returns 'string'/'number'/'boolean'/'null'.
// ---------------------------------------------------------------------------
function mcItemToElementType(item : TMcJsonItem) : TgsJsonElementType;
var
  vstr : string;
begin
  if item = nil then begin
    result := TgsJsonElementType.etEmpty;
    exit;
  end;
  case item.ItemType of
    jitUnset  : result := TgsJsonElementType.etEmpty;
    jitObject : result := TgsJsonElementType.etJson;
    jitArray  : result := TgsJsonElementType.etJsonArray;
    jitValue  : begin
      if item.IsNull then begin
        result := TgsJsonElementType.etNull;
        exit;
      end;
      vstr := item.GetValueStr;   // returns 'string', 'number', 'boolean', 'null'
      if      vstr = 'string'  then result := TgsJsonElementType.etString
      else if vstr = 'number'  then result := TgsJsonElementType.etNumber
      else if vstr = 'boolean' then result := TgsJsonElementType.etBoolean
      else if vstr = 'null'    then result := TgsJsonElementType.etNull
      else                          result := TgsJsonElementType.etEmpty;
    end;
  else
    result := TgsJsonElementType.etEmpty;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : share a TMcJsonItem reference into an igsJson wrapper (not owned)
// The source item is owned by the parent FJson tree — do NOT free it here.
// ---------------------------------------------------------------------------
procedure extractValue(source : TMcJsonItem; var value : igsJson);
var
  w : TgsJsonImplMc;
begin
  if not assigned(value) then
    value := TgsJsonImplMc.Create;

  w := TgsJsonImplMc(value);
  // Free any previously owned item
  if w.FOwned and (w.FJson <> nil) then
    w.FJson.Free;
  w.FJson  := source;
  w.FOwned := false;  // not owned: parent tree owns it
end;

// ---------------------------------------------------------------------------
// Helper : ensure FJson is in Object mode
// ---------------------------------------------------------------------------
procedure ensureObject(var FJson : TMcJsonItem; var FOwned : boolean);
begin
  if FJson = nil then begin
    FJson := TMcJsonItem.Create;
    FOwned := true;
  end;
  if FJson.ItemType = jitUnset then
    FJson.ItemType := jitObject;
  // If already object, fine. If array, we leave it (caller's responsibility).
end;

// ---------------------------------------------------------------------------
// Helper : ensure FJson is in Array mode
// ---------------------------------------------------------------------------
procedure ensureArray(var FJson : TMcJsonItem; var FOwned : boolean);
begin
  if FJson = nil then begin
    FJson := TMcJsonItem.Create;
    FOwned := true;
  end;
  if FJson.ItemType = jitUnset then
    FJson.ItemType := jitArray;
end;

// ---------------------------------------------------------------------------
// Helper : put or update a named key in an object
// ---------------------------------------------------------------------------
procedure putValue(FJson : TMcJsonItem; const name : string;
  proc : TProc<TMcJsonItem>);
var
  item : TMcJsonItem;
begin
  if FJson.IndexOf(name) > -1 then
    item := FJson.Values[name]
  else
    item := FJson.Add(name);
  proc(item);
end;

// ---------------------------------------------------------------------------
// Helper : add array-of-const to a TMcJsonItem array
// ---------------------------------------------------------------------------
procedure addConstToMc(FJson : TMcJsonItem; const vals : array of const);
var
  i : integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString        : FJson.Add.AsString  := String(vals[i].VString^);
      vtWideString    : FJson.Add.AsString  := String(vals[i].VWideString);
      vtUnicodeString : FJson.Add.AsString  := UnicodeString(vals[i].VUnicodeString);
      vtAnsiString    : FJson.Add.AsString  := String(AnsiString(vals[i].VAnsiString));
      vtInteger       : FJson.Add.AsInteger := vals[i].VInteger;
      System.vtBoolean: FJson.Add.AsBoolean := vals[i].VBoolean;
      vtExtended      : FJson.Add.AsNumber  := vals[i].VExtended^;
      vtInt64         : FJson.Add.AsInteger := Integer(vals[i].VInt64^);
      vtCurrency      : FJson.Add.AsNumber  := Double(vals[i].VCurrency^);
    end;
  end;
end;

{ TgsJsonImplMc }

constructor TgsJsonImplMc.Create;
begin
  FJson  := TMcJsonItem.Create;
  FOwned := true;
end;

destructor TgsJsonImplMc.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplMc.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FJson.Clear
  else begin
    FJson  := TMcJsonItem.Create;
    FOwned := true;
  end;
  FJson.AsJSON := aJsonStr;
end;

// ---------------------------------------------------------------------------
// put — object mode
// ---------------------------------------------------------------------------

function TgsJsonImplMc.put(name: string; val: double): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  putValue(FJson, name, procedure(item : TMcJsonItem) begin
    item.AsNumber := val;
  end);
end;

function TgsJsonImplMc.put(name, val: string): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  putValue(FJson, name, procedure(item : TMcJsonItem) begin
    item.AsString := val;
  end);
end;

function TgsJsonImplMc.put(name: string; val: boolean): igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
  putValue(FJson, name, procedure(item : TMcJsonItem) begin
    item.AsBoolean := val;
  end);
end;

function TgsJsonImplMc.put(name: string; vals: array of const): igsJson;
var
  arr : TMcJsonItem;
begin
  result := self;
  ensureObject(FJson, FOwned);
  // Delete existing key if present, then create a fresh array child
  if FJson.IndexOf(name) > -1 then
    FJson.Delete(name);
  arr := FJson.Add(name, jitArray);
  addConstToMc(arr, vals);
end;

function TgsJsonImplMc.put(name: string; val: igsJson): igsJson;
var
  sub : TMcJsonItem;
begin
  result := self;
  ensureObject(FJson, FOwned);
  if FJson.IndexOf(name) > -1 then
    FJson.Delete(name);
  sub := FJson.Add(name);
  sub.AsJSON := val.stringify;
end;

// ---------------------------------------------------------------------------
// put — array mode
// ---------------------------------------------------------------------------

function TgsJsonImplMc.put(vals: array of const): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  addConstToMc(FJson, vals);
end;

function TgsJsonImplMc.put(val: igsJson): igsJson;
var
  item : TMcJsonItem;
begin
  result := self;
  ensureArray(FJson, FOwned);
  item := FJson.Add;
  item.AsJSON := val.stringify;
end;

// ---------------------------------------------------------------------------
// stringify
// ---------------------------------------------------------------------------

function TgsJsonImplMc.stringify(var aStr: string): igsJson;
begin
  result := self;
  aStr := FJson.AsJSON;
end;

function TgsJsonImplMc.stringify: string;
begin
  result := FJson.AsJSON;
end;

// ---------------------------------------------------------------------------
// get — scalars by name
// ---------------------------------------------------------------------------

function TgsJsonImplMc.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FJson.ItemType <> jitObject then
    raise Exception.Create('TgsJsonImplMc.get: Not an object');
  value := FJson.Values[name].AsString;
end;

function TgsJsonImplMc.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FJson.ItemType <> jitObject then
    raise Exception.Create('TgsJsonImplMc.get: Not an object');
  value := FJson.Values[name].AsInteger;
end;

function TgsJsonImplMc.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FJson.ItemType <> jitObject then
    raise Exception.Create('TgsJsonImplMc.get: Not an object');
  value := FJson.Values[name].AsNumber;
end;

function TgsJsonImplMc.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FJson.ItemType <> jitObject then
    raise Exception.Create('TgsJsonImplMc.get: Not an object');
  value := FJson.Values[name].AsBoolean;
end;

// ---------------------------------------------------------------------------
// get — scalars by index
// ---------------------------------------------------------------------------

function TgsJsonImplMc.get(index: integer; var value: string): igsJson;
begin
  result := self;
  assert(index < FJson.Count);
  value := FJson.Items[index].AsString;
end;

function TgsJsonImplMc.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  assert(index < FJson.Count);
  value := FJson.Items[index].AsInteger;
end;

function TgsJsonImplMc.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  assert(index < FJson.Count);
  value := FJson.Items[index].AsNumber;
end;

function TgsJsonImplMc.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  assert(index < FJson.Count);
  value := FJson.Items[index].AsBoolean;
end;

// ---------------------------------------------------------------------------
// get — object/array by name or index (shared reference, not owned)
// ---------------------------------------------------------------------------

function TgsJsonImplMc.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FJson.ItemType <> jitObject then
    raise Exception.Create('TgsJsonImplMc.get: Not an object');
  if FJson.IndexOf(name) < 0 then
    raise Exception.Create('TgsJsonImplMc.get: Key not found: ' + name);
  extractValue(FJson.Values[name], value);
end;

function TgsJsonImplMc.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  assert(index < FJson.Count);
  extractValue(FJson.Items[index], value);
end;

// ---------------------------------------------------------------------------
// Analyses
// ---------------------------------------------------------------------------

function TgsJsonImplMc.jsonElementCount: integer;
begin
  result := FJson.Count;
end;

function TgsJsonImplMc.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if (FJson = nil) or (index >= FJson.Count) then
    exit;
  result := mcItemToElementType(FJson.Items[index]);
end;

function TgsJsonImplMc.jsonType: TgsJsonElementType;
begin
  if FJson = nil then begin
    result := TgsJsonElementType.etEmpty;
    exit;
  end;
  result := mcItemToElementType(FJson);
end;

function TgsJsonImplMc.jsonElementName(index: integer): string;
begin
  if FJson.ItemType <> jitObject then
    raise Exception.Create('TgsJsonImplMc.jsonElementName: Not an object');
  assert(index < FJson.Count);
  result := FJson.Items[index].Key;
end;

// ---------------------------------------------------------------------------
// clear
// ---------------------------------------------------------------------------

function TgsJsonImplMc.clear: igsJson;
begin
  result := self;
  FJson.Clear;
end;

// ---------------------------------------------------------------------------
// asXxx convenience wrappers
// ---------------------------------------------------------------------------

function TgsJsonImplMc.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplMc.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplMc.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplMc.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplMc.asObj(name: String): igsJson;
begin
  result := nil;
  get(name, result);
end;

function TgsJsonImplMc.asObj(index: integer): igsJson;
begin
  result := nil;
  get(index, result);
end;

// ---------------------------------------------------------------------------
// add — array mode
// ---------------------------------------------------------------------------

function TgsJsonImplMc.add(val: igsJson): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Add.AsJSON := val.stringify;
end;

function TgsJsonImplMc.add(val: double): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Add.AsNumber := val;
end;

function TgsJsonImplMc.add(val: integer): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Add.AsInteger := val;
end;

function TgsJsonImplMc.add(val: string): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Add.AsString := val;
end;

function TgsJsonImplMc.add(val: byte): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Add.AsInteger := val;
end;

function TgsJsonImplMc.add(val: boolean): igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
  FJson.Add.AsBoolean := val;
end;

// ---------------------------------------------------------------------------
// isNameExists
// ---------------------------------------------------------------------------

function TgsJsonImplMc.isNameExists(name: String): boolean;
begin
  result := (FJson.ItemType = jitObject) and (FJson.IndexOf(name) > -1);
end;

// ---------------------------------------------------------------------------
// ToObj / ToArray — force item type
// ---------------------------------------------------------------------------

function TgsJsonImplMc.ToObj: igsJson;
begin
  result := self;
  ensureObject(FJson, FOwned);
end;

function TgsJsonImplMc.ToArray: igsJson;
begin
  result := self;
  ensureArray(FJson, FOwned);
end;

{ TgsJsonImplMcFactory }

function TgsJsonImplMcFactory.getAuthor: string;
begin
  result := 'hydrobyte (McJSON)';
end;

function TgsJsonImplMcFactory.getTitle: string;
begin
  result := 'McJSON';
end;

function TgsJsonImplMcFactory.getDesc: string;
begin
  result := 'McJSON - TMcJsonItem based implementation';
end;

function TgsJsonImplMcFactory.getId: string;
begin
  result := 'mcjson';
end;

function TgsJsonImplMcFactory.getJson: igsJson;
begin
  result := TgsJsonImplMc.Create;
end;

initialization

addImplementation(TgsJsonImplMcFactory.Create);

end.

