///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.dynamicDataObjects;

interface

uses sysutils,
     classes,
     gs.Json,
     DataObjects2,
     DataObjects2JSON;

type

TgsJsonImplDynDataObj = class(TInterfacedObject, igsJson)
private
protected
  FData : TDataObj;
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

TgsJsonImplDynDataObjFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

function dataObjToElementType(aObj : TDataObj) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aObj = nil then
    exit;
  case aObj.DataType.Code of
    cDataTypeNull : result := TgsJsonElementType.etNull;
    cDataTypeBoolean : result := TgsJsonElementType.etBoolean;
    cDataTypeByte,
    cDataTypeInt32,
    cDataTypeInt64,
    cDataTypeSingle,
    cDataTypeDouble : result := TgsJsonElementType.etNumber;
    cDataTypeString : result := TgsJsonElementType.etString;
    cDataTypeFrame,
    cDataTypeObject : result := TgsJsonElementType.etJson;
    cDataTypeArray : result := TgsJsonElementType.etJsonArray;
  end;
end;

procedure extractValue(source : TDataObj; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplDynDataObj.Create;

  if TgsJsonImplDynDataObj(value).FOwned and (TgsJsonImplDynDataObj(value).FData <> nil) then
    TgsJsonImplDynDataObj(value).FData.Free;
  TgsJsonImplDynDataObj(value).FData := source;
  TgsJsonImplDynDataObj(value).FOwned := false;
end;

function getAsFrame(var FData : TDataObj; var FOwned : boolean) : TDataFrame;
begin
  // If FData is nil, create a new one
  if FData = nil then begin
    FData := TDataObj.Create;
    FOwned := true;
  end;
  // AsFrame will convert the TDataObj to a frame type if it isn't already
  result := FData.AsFrame;
end;

function getAsArr(var FData : TDataObj; var FOwned : boolean) : TDataArray;
begin
  // If FData is nil, create a new one
  if FData = nil then begin
    FData := TDataObj.Create;
    FOwned := true;
  end;
  // AsArray will convert the TDataObj to an array type if it isn't already
  result := FData.AsArray;
end;

procedure addToArray(arr : TDataArray; const vals : array of const);
begin
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : arr.NewSlot.AsString := String(vals[i].VString^);
      vtWideString : arr.NewSlot.AsString := String(vals[i].VWideString);
      vtUnicodeString : arr.NewSlot.AsString := UnicodeString(vals[i].VUnicodeString);
      vtInteger : arr.NewSlot.AsInt32 := vals[i].VInteger;
      vtBoolean : arr.NewSlot.AsBoolean := vals[i].VBoolean;
      vtExtended : arr.NewSlot.AsDouble := vals[i].VExtended^;
    end;
  end;
end;

{ TgsJsonImplDynDataObj }

constructor TgsJsonImplDynDataObj.Create;
begin
  FData := nil;
  FOwned := true;
end;

destructor TgsJsonImplDynDataObj.Destroy;
begin
  if FOwned and (FData <> nil) then
    FreeAndNil(FData);
  inherited;
end;

function TgsJsonImplDynDataObj.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FData <> nil) then
    FreeAndNil(FData);
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FData := TDataObj.Create;
  FOwned := true;
  TJsonStreamer.JsonToDataObj(trimmed, FData);
end;

function TgsJsonImplDynDataObj.put(name: string; val: double): igsJson;
begin
  result := self;
  var frame := getAsFrame(FData, FOwned);
  // Delete existing slot if present, then create new one
  frame.DeleteSlot(name);
  frame.NewSlot(name).AsDouble := val;
end;

function TgsJsonImplDynDataObj.put(name, val: string): igsJson;
begin
  result := self;
  var frame := getAsFrame(FData, FOwned);
  frame.DeleteSlot(name);
  frame.NewSlot(name).AsString := val;
end;

function TgsJsonImplDynDataObj.put(name: string; val: boolean): igsJson;
begin
  result := self;
  var frame := getAsFrame(FData, FOwned);
  frame.DeleteSlot(name);
  frame.NewSlot(name).AsBoolean := val;
end;

function TgsJsonImplDynDataObj.put(vals: array of const): igsJson;
begin
  result := self;
  var arr := getAsArr(FData, FOwned);
  addToArray(arr, vals);
end;

function TgsJsonImplDynDataObj.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  var frame := getAsFrame(FData, FOwned);
  frame.DeleteSlot(name);
  var slot := frame.NewSlot(name);
  var arr := slot.AsArray;
  addToArray(arr, vals);
end;

function TgsJsonImplDynDataObj.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  var frame := getAsFrame(FData, FOwned);
  frame.DeleteSlot(name);
  var slot := frame.NewSlot(name);
  // Parse the JSON string from the source into the new slot
  TJsonStreamer.JsonToDataObj(val.stringify, slot);
end;

function TgsJsonImplDynDataObj.put(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FData, FOwned);
  var slot := arr.NewSlot;
  TJsonStreamer.JsonToDataObj(val.stringify, slot);
end;

function TgsJsonImplDynDataObj.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FData <> nil then
    aStr := TJsonStreamer.DataObjToJson(FData)
  else
    aStr := 'null';
end;

function TgsJsonImplDynDataObj.stringify: string;
begin
  if FData <> nil then
    result := TJsonStreamer.DataObjToJson(FData)
  else
    result := 'null';
end;

function TgsJsonImplDynDataObj.get(name: string; var value: string): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    var slot := FData.AsFrame.FindSlot(name);
    if slot <> nil then
      value := slot.AsString
    else
      raise Exception.Create('TgsJsonImplDynDataObj.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDynDataObj.get: Not an object');
end;

function TgsJsonImplDynDataObj.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    assert(index < FData.AsFrame.Count);
    value := FData.AsFrame.Slots[index].AsString;
  end
  else if (FData <> nil) and (FData.DataType.Code = cDataTypeArray) then begin
    assert(index < FData.AsArray.Count);
    value := FData.AsArray.Slots[index].AsString;
  end;
end;

function TgsJsonImplDynDataObj.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    var slot := FData.AsFrame.FindSlot(name);
    if slot <> nil then
      value := slot.AsInt32
    else
      raise Exception.Create('TgsJsonImplDynDataObj.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDynDataObj.get: Not an object');
end;

function TgsJsonImplDynDataObj.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    assert(index < FData.AsFrame.Count);
    value := FData.AsFrame.Slots[index].AsInt32;
  end
  else if (FData <> nil) and (FData.DataType.Code = cDataTypeArray) then begin
    assert(index < FData.AsArray.Count);
    value := FData.AsArray.Slots[index].AsInt32;
  end;
end;

function TgsJsonImplDynDataObj.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    var slot := FData.AsFrame.FindSlot(name);
    if slot <> nil then
      value := slot.AsDouble
    else
      raise Exception.Create('TgsJsonImplDynDataObj.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDynDataObj.get: Not an object');
end;

function TgsJsonImplDynDataObj.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    assert(index < FData.AsFrame.Count);
    value := FData.AsFrame.Slots[index].AsDouble;
  end
  else if (FData <> nil) and (FData.DataType.Code = cDataTypeArray) then begin
    assert(index < FData.AsArray.Count);
    value := FData.AsArray.Slots[index].AsDouble;
  end;
end;

function TgsJsonImplDynDataObj.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    var slot := FData.AsFrame.FindSlot(name);
    if slot <> nil then
      value := slot.AsBoolean
    else
      raise Exception.Create('TgsJsonImplDynDataObj.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDynDataObj.get: Not an object');
end;

function TgsJsonImplDynDataObj.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    assert(index < FData.AsFrame.Count);
    value := FData.AsFrame.Slots[index].AsBoolean;
  end
  else if (FData <> nil) and (FData.DataType.Code = cDataTypeArray) then begin
    assert(index < FData.AsArray.Count);
    value := FData.AsArray.Slots[index].AsBoolean;
  end;
end;

function TgsJsonImplDynDataObj.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    var slot := FData.AsFrame.FindSlot(name);
    if slot <> nil then
      extractValue(slot, value)
    else
      raise Exception.Create('TgsJsonImplDynDataObj.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplDynDataObj.get: Not an object');
end;

function TgsJsonImplDynDataObj.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    assert(index < FData.AsFrame.Count);
    extractValue(FData.AsFrame.Slots[index], value);
  end
  else if (FData <> nil) and (FData.DataType.Code = cDataTypeArray) then begin
    assert(index < FData.AsArray.Count);
    extractValue(FData.AsArray.Slots[index], value);
  end;
end;

function TgsJsonImplDynDataObj.jsonElementCount: integer;
begin
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then
    result := FData.AsFrame.Count
  else if (FData <> nil) and (FData.DataType.Code = cDataTypeArray) then
    result := FData.AsArray.Count
  else
    result := -1;
end;

function TgsJsonImplDynDataObj.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then
    result := dataObjToElementType(FData.AsFrame.Slots[index])
  else if (FData <> nil) and (FData.DataType.Code = cDataTypeArray) then
    result := dataObjToElementType(FData.AsArray.Slots[index]);
end;

function TgsJsonImplDynDataObj.jsonType: TgsJsonElementType;
begin
  result := dataObjToElementType(FData);
end;

function TgsJsonImplDynDataObj.jsonElementName(index: integer): string;
begin
  result := '';
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then begin
    assert(index < FData.AsFrame.Count);
    result := FData.AsFrame.Slotname(index);
  end
  else
    raise Exception.Create('TgsJsonImplDynDataObj.jsonElementName: Not an object');
end;

function TgsJsonImplDynDataObj.clear: igsJson;
begin
  result := self;
  if FOwned and (FData <> nil) then
    FreeAndNil(FData);
  FData := nil;
  FOwned := true;
end;

function TgsJsonImplDynDataObj.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplDynDataObj.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplDynDataObj.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplDynDataObj.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplDynDataObj.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplDynDataObj.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplDynDataObj.add(val: igsJson): igsJson;
begin
  result := self;
  var arr := getAsArr(FData, FOwned);
  var slot := arr.NewSlot;
  TJsonStreamer.JsonToDataObj(val.stringify, slot);
end;

function TgsJsonImplDynDataObj.add(val: double): igsJson;
begin
  result := self;
  var arr := getAsArr(FData, FOwned);
  arr.NewSlot.AsDouble := val;
end;

function TgsJsonImplDynDataObj.add(val: integer): igsJson;
begin
  result := self;
  var arr := getAsArr(FData, FOwned);
  arr.NewSlot.AsInt32 := val;
end;

function TgsJsonImplDynDataObj.add(val: string): igsJson;
begin
  result := self;
  var arr := getAsArr(FData, FOwned);
  arr.NewSlot.AsString := val;
end;

function TgsJsonImplDynDataObj.add(val: byte): igsJson;
begin
  result := self;
  var arr := getAsArr(FData, FOwned);
  arr.NewSlot.AsInt32 := Integer(val);
end;

function TgsJsonImplDynDataObj.add(val: boolean): igsJson;
begin
  result := self;
  var arr := getAsArr(FData, FOwned);
  arr.NewSlot.AsBoolean := val;
end;

function TgsJsonImplDynDataObj.isNameExists(name: String): boolean;
begin
  result := false;
  if (FData <> nil) and (FData.DataType.Code = cDataTypeFrame) then
    result := FData.AsFrame.FindSlot(name) <> nil;
end;

function TgsJsonImplDynDataObj.ToObj: igsJson;
begin
  result := self;
  if FData = nil then begin
    FData := TDataObj.Create;
    FOwned := true;
  end;
  // Accessing AsFrame will convert the TDataObj to frame type if needed
  if FData.DataType.Code <> cDataTypeFrame then begin
    if FOwned then
      FData.Clear;
    FData.AsFrame;
  end;
end;

function TgsJsonImplDynDataObj.ToArray: igsJson;
begin
  result := self;
  if FData = nil then begin
    FData := TDataObj.Create;
    FOwned := true;
  end;
  // Accessing AsArray will convert the TDataObj to array type if needed
  if FData.DataType.Code <> cDataTypeArray then begin
    if FOwned then
      FData.Clear;
    FData.AsArray;
  end;
end;

{ TgsJsonImplDynDataObjFactory }

function TgsJsonImplDynDataObjFactory.getAuthor: string;
begin
  result := 'Sean Solberg';
end;

function TgsJsonImplDynDataObjFactory.getTitle: string;
begin
  result := 'DynamicDataObjects';
end;

function TgsJsonImplDynDataObjFactory.getDesc: string;
begin
  result := 'Dynamic Data Objects Library - universal data container with JSON serialization';
end;

function TgsJsonImplDynDataObjFactory.getId: string;
begin
  result := 'dynamicdataobjects';
end;

function TgsJsonImplDynDataObjFactory.getJson: igsJson;
begin
  result := TgsJsonImplDynDataObj.Create;
end;

initialization

addImplementation(TgsJsonImplDynDataObjFactory.Create);

end.
