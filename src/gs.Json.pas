///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************


unit gs.Json;

interface

uses sysutils;

Type
TgsJsonElementType = (etEmpty, etNull, etNumber, etString, etBoolean, etJson, etJsonArray);

JsonException = class(Exception);

igsJson = interface
  function parse(aJsonStr : string) : igsJson;
  { TODO : put instead of add. Put modify too, not only adding. }
  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;

  //Add an array.
  // myjson.add('',[]);
  // myjson.add('values',['hi',1,2,0.1,ajs]);
  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;
  function add(val : igsJson) : igsJson; overload;
  function add(val : double) : igsJson; overload;
  function add(val : integer) : igsJson; overload;
  function add(val : string) : igsJson; overload;
  function add(val : byte) : igsJson; overload;
  function add(val : boolean) : igsJson; overload;


  //Add an object.
  function put(name : string; val : igsJson) : igsJson; overload;
  function put(val : igsJson) : igsJson; overload;

  //transform into json string.
  function stringify(var aStr : string) : igsJson; overload;
  function stringify : string; overload;

  //Get (in a json or array object oriented)
  /// Index :
  /// -> field sequenced access in a json object.
  /// -> array access in a jsonArray object.
  function get(name : string; var value : string) : igsJson; overload;
  function get(index : integer; var value : string) : igsJson; overload;
  function get(name : string; var value : integer) : igsJson; overload;
  function get(index : integer; var value : integer) : igsJson; overload;
  function get(name : string; var value : Double) : igsJson; overload;
  function get(index : integer; var value : Double) : igsJson; overload;
  function get(name : string; var value : Boolean) : igsJson; overload;
  function get(index : integer; var value : Boolean) : igsJson; overload;

  //Get (in a json object oriented) - value is the inner json object, into current json.
  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  //Analyses.
  function jsonElementCount : integer;
  function jsonType : TgsJsonElementType; //Root type.
  function jsonElementType(index : integer) : TgsJsonElementType; //element type.
  function jsonElementName(index : integer) : string;

  //Clear ??
  function clear : igsJson;
  //function remove(index : integer) : igsJson;
  //function remove(name : string) : igsJson;

  //Easy access to base type.
  //this code use interface level, you can cut and copy
  //for adapt to other impls libs. (see code, available for all type.
  function asString(name : String) : string;
  /// begin
  ///   get(name,result);
  /// end;

  function asInteger(name : String) : integer;
  function asNumber(name : String) : double;
  function asBoolean(name : String) : Boolean;
  function asObj(name : String) : igsJson; overload; //Or array !
  function asObj(index : integer) : igsJson; Overload; //Obj Or array !

  function isNameExists(name : String) : boolean;

  function ToObj : igsJson;
  function ToArray : igsJson;
end;


//Json factory.
igsJsonFactory = interface
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string; //Id for identify json lib. Van be used in factory.
  function getJson : igsJson;
end;


//Injection : implementation, you can use this to register yout factory (see gs.json.impl.delphi4Json)
procedure addImplementation(factory : igsJsonFactory);

//act as factory.
function createJson(const factoryId : string = '') : igsjson;

//create a new interface from an existing interface
function cloneJson(const ASource: igsJson; const factoryId : string = '') : igsJson;


//general utility.
function JSONDateToString(aDate : TDateTime) : String;
function JSONStringToDate(aDate : String) : TDateTime;
//Test is format is correct.
function JSONStringIsCompatibleDate(aJSONDate : String) : boolean;


implementation

uses dateutils; //conversion utility.

var localDefaultSingletonFactories : TArray<igsJsonFactory>;

procedure AddImplementation(factory : igsJsonFactory);
begin
  assert(Assigned( factory ));
  var li := length( localDefaultSingletonFactories );
  SetLength( localDefaultSingletonFactories,li+1 );
  localDefaultSingletonFactories[li] := factory;
end;

function createJson(const factoryId : string = '') : igsjson;
begin
  if factoryId.Trim.Length>0 then begin
    for var i := Low( localDefaultSingletonFactories ) to High( localDefaultSingletonFactories ) do begin
      if localDefaultSingletonFactories[i].getId.Trim.ToLower = factoryId.Trim.ToLower then begin
        result := localDefaultSingletonFactories[i].getJson;
        break;
      end;
    end;
  end else begin
    if Length(localDefaultSingletonFactories)>0 then
      result := localDefaultSingletonFactories[0].getJson;
  end;

  assert(assigned( Result ),'Json factory not found');
end;

function cloneJson(const ASource: igsJson; const factoryId : string = '') : igsjson;
begin
  assert(Assigned(ASource), 'ASource is not assigned');
  result := createJson(factoryId).parse(ASource.stringify);
end;

//JSON date base conversion utility : taken "as is" from but quite incomplete. Will be replaced. TODO.
function ZeroFillStr(Number, Size : integer) : String;
begin
  Result := IntToStr(Number);
  while length(Result) < Size do
    Result := '0'+Result;
end;

function JSONDateToString(aDate : TDateTime) : String;
begin
  Result := ZeroFillStr(YearOf(aDate),4)+'-'+
            ZeroFillStr(MonthOf(aDate),2)+'-'+
            ZeroFillStr(DayOf(aDate),2)+'T'+
            ZeroFillStr(HourOf(aDate),2)+':'+
            ZeroFillStr(MinuteOf(aDate),2)+':'+
            ZeroFillStr(SecondOf(aDate),2)+'.'+
            ZeroFillStr(MilliSecondOf(aDate),3)+'Z';
end;

function JSONStringToDate(aDate : String) : TDateTime;
begin
  Result :=
    EncodeDateTime(
      StrToInt(Copy(aDate,1,4)),
      StrToInt(Copy(aDate,6,2)),
      StrToInt(Copy(aDate,9,2)),
      StrToInt(Copy(aDate,12,2)),
      StrToInt(Copy(aDate,15,2)),
      StrToInt(Copy(aDate,18,2)),
      StrToInt(Copy(aDate,21,3)));
end;

//Testing.
function JSONStringIsCompatibleDate(aJSONDate : String) : boolean;
var ldummy: integer;
    lval, lnum : Boolean;
begin
  lval := TryStrToInt(Copy(aJSONDate,1,4),ldummy) and  TryStrToInt(Copy(aJSONDate,6,2),ldummy) and
          TryStrToInt(Copy(aJSONDate,9,2),ldummy) and  TryStrToInt(Copy(aJSONDate,12,2),ldummy) and
          TryStrToInt(Copy(aJSONDate,15,2),ldummy) and TryStrToInt(Copy(aJSONDate,18,2),ldummy) and
          TryStrToInt(Copy(aJSONDate,21,3),ldummy);

  lnum := (Length(aJSONDate)=24) and
            (aJSONDate[5] = '-') and
            (aJSONDate[8] = '-') and
            (aJSONDate[11] = 'T') and
            (aJSONDate[14] = ':') and
            (aJSONDate[17] = ':') and
            (aJSONDate[20] = '.') and
            (aJSONDate[24] = 'Z');

  Result := lval and lNum;
end;


initialization


finalization

end.
