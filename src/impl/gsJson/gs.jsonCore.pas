///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
{****************************************************************************

201803 - Original file form Randolph mail: rilyu@sina.com
201804 - Fix - VGS - Refactor FixedFloatToStr (best use case and optimization)
201805 - Add - VGS - Add OBjectToJson and JsonToObject, rtti based, cross platform Delphi10+ and FPC 3+Refactor
201807 - Fix - VGS - String unicode (\uxxx) encoding and decoding.
202402 - Add - VGS - Change name, refactoring, andmerge utility.
202403 - fix - VGS - parsing "special" file - test accuracy.
         fix - VGS - Check unicity in same level name in an object.
         fix - VGS - Line break check into json string.

****************************************************************************}

unit gs.jsonCore;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

{$DEFINE LINEBREAKJSONFORMAT} //Desactivate for a non "minimal better human-readable format".

interface

uses Classes,
     SysUtils;

type
  TJsonValueType = (jvNone, jvNull, jvString, jvNumber, jvBoolean, jvObject, jvArray);
  TJsonStructType = (jsNone, jsArray, jsObject);
  TJsonNull = (null);
  TJsonEmpty = (empty);

type
  TJsonBase = class(TObject)
  private
    FOwner: TJsonBase;
    function GetOwner: TJsonBase;

  protected
    function GetOwnerName: String;
    procedure RaiseError(const Msg: String);
    procedure RaiseParseError(const JsonString: String);
    procedure RaiseAssignError(Source: TJsonBase);

  public
    constructor Create(AOwner: TJsonBase);
    destructor Destroy; override;

    procedure Parse(JsonString: String); virtual; abstract;
    function Stringify: String; virtual; abstract;

    procedure Assign(Source: TJsonBase); virtual; abstract;

    function Encode(const S: String): String;
    function Decode(const S: String): String;

    procedure Split(const S: String; const Delimiter: Char; Strings: TStrings);

    function IsJsonObject(const S: String): Boolean;
    function IsJsonArray(const S: String): Boolean;
    function IsJsonString(const S: String): Boolean;
    function IsJsonNumber(const S: String): Boolean;
    function IsJsonBoolean(const S: String): Boolean;
    function IsJsonNull(const S: String): Boolean;

    function AnalyzeJsonValueType(const S: String): TJsonValueType;

  public
    property Owner: TJsonBase read GetOwner;

  end;

  TJsonObject = class;
  TJsonArray = class;
  TJsonValue = class(TJsonBase)
  private
    FValueType: TJsonValueType;
    FStringValue: String;
    FNumberValue: Extended;
    FBooleanValue: Boolean;
    FObjectValue: TJsonObject;
    FArrayValue: TJsonArray;

    function GetAsArray: TJsonArray;
    function GetAsBoolean: Boolean;
    function GetAsInteger: Integer;
    function GetAsNumber: Extended;
    function GetAsObject: TJsonObject;
    function GetAsString: String;
    function GetIsNull: Boolean;
    procedure SetAsBoolean(const Value: Boolean);
    procedure SetAsInteger(const Value: Integer);
    procedure SetAsNumber(const Value: Extended);
    procedure SetAsString(const Value: String);
    procedure SetIsNull(const Value: Boolean);
    procedure SetAsArray(const Value: TJsonArray);
    procedure SetAsObject(const Value: TJsonObject);
    function GetIsEmpty: Boolean;
    procedure SetIsEmpty(const Value: Boolean);

  protected
    procedure RaiseValueTypeError(const AsValueType: TJsonValueType);

  public
    constructor Create(AOwner: TJsonBase);
    destructor Destroy; override;

    procedure Parse(JsonString: String); override;
    function Stringify: String; override;

    procedure Assign(Source: TJsonBase); override;

    procedure Clear;

  public
    property ValueType: TJsonValueType read FValueType write FValueType;
    property AsString: String read GetAsString write SetAsString;
    property AsNumber: Extended read GetAsNumber write SetAsNumber;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsObject: TJsonObject read GetAsObject write SetAsObject;
    property AsArray: TJsonArray read GetAsArray write SetAsArray;
    property IsNull: Boolean read GetIsNull write SetIsNull;
    property IsEmpty: Boolean read GetIsEmpty write SetIsEmpty;

  end;

  TJsonArray = class(TJsonBase)
  private
    FList: TList;
    function GetItems(Index: Integer): TJsonValue;
    function GetCount: Integer;
  public
    constructor Create(AOwner: TJsonBase = nil);
    destructor Destroy; override;

    procedure Parse(JsonString: String); override;
    function Stringify: String; override;

    procedure Assign(Source: TJsonBase); override;
    procedure Merge(Addition: TJsonArray);

    function Add: TJsonValue;
    function Insert(const Index: Integer): TJsonValue;

    function Put(const Value: TJsonEmpty): TJsonValue; overload;
    function Put(const Value: TJsonNull): TJsonValue; overload;
    function Put(const Value: Boolean): TJsonValue; overload;
    function Put(const Value: Integer): TJsonValue; overload;
    function Put(const Value: Extended): TJsonValue; overload;
    function Put(const Value: String): TJsonValue; overload;
    function Put(const Value: TJsonArray): TJsonValue; overload;
    function Put(const Value: TJsonObject): TJsonValue; overload;
    function Put(const Value: TJsonValue): TJsonValue; overload;

    procedure Delete(const Index: Integer);
    procedure Clear;

  public
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TJsonValue read GetItems; default;

  end;

  TJsonPair = class(TJsonBase)
  private
    FName: String;
    FValue: TJsonValue;

    procedure SetName(const Value: String);

  public
    constructor Create(AOwner: TJsonBase; const AName: String = '');
    destructor Destroy; override;

    procedure Parse(JsonString: String); override;
    function Stringify: String; override;

    procedure Assign(Source: TJsonBase); override;

  public
    property Name: String read FName write SetName;
    property Value: TJsonValue read FValue;

  end;

  TJsonObject = class(TJsonBase)
  private
    FList: TList;
    function GetCount: Integer;
    function GetPairs(Index: Integer): TJsonPair;
    function GetValues(Name: String): TJsonValue;
  public
    constructor Create(AOwner: TJsonBase = nil);
    destructor Destroy; override;

    procedure Parse(JsonString: String); override;
    function Stringify: String; override;

    procedure Assign(Source: TJsonBase); override;
    procedure Merge(Addition: TJsonObject);

    function Add(const Name: String = ''): TJsonPair;
    function Insert(const Index: Integer; const Name: String = ''): TJsonPair;

    function Put(const Name: String; const Value: TJsonEmpty): TJsonValue; overload;
    function Put(const Name: String; const Value: TJsonNull): TJsonValue; overload;
    function Put(const Name: String; const Value: Boolean): TJsonValue; overload;
    function Put(const Name: String; const Value: Integer): TJsonValue; overload;
    function Put(const Name: String; const Value: Extended): TJsonValue; overload;
    function Put(const Name: String; const Value: String): TJsonValue; overload;
    function Put(const Name: String; const Value: TJsonArray): TJsonValue; overload;
    function Put(const Name: String; const Value: TJsonObject): TJsonValue; overload;
    function Put(const Name: String; const Value: TJsonValue): TJsonValue; overload;
    function Put(const Value: TJsonPair): TJsonValue; overload;

    function Find(const Name: String): Integer;

    procedure Delete(const Index: Integer); overload;
    procedure Delete(const Name: String); overload;

    procedure Clear;

  public
    property Count: Integer read GetCount;
    property Pairs[Index: Integer]: TJsonPair read GetPairs;
    property Values[Name: String]: TJsonValue read GetValues; default;

  end;

  TJson = class(TJsonBase)
  private
    FStructType: TJsonStructType;
    FJsonArray: TJsonArray;
    FJsonObject: TJsonObject;

    function GetCount: Integer;
    function GetJsonArray: TJsonArray;
    function GetJsonObject: TJsonObject;
    function GetValues(Name: String): TJsonValue;
  protected
    procedure CreateArrayIfNone;
    procedure CreateObjectIfNone;

    procedure RaiseIfNone;
    procedure RaiseIfNotArray;
    procedure RaiseIfNotObject;

    procedure CheckJsonArray;
    procedure CheckJsonObject;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Parse(JsonString: String); override;
    function Stringify: String; override;

    procedure Assign(Source: TJsonBase); override;

    procedure Delete(const Index: Integer); overload;
    procedure Delete(const Name: String); overload;

    procedure Clear;

    function Get(const Index: Integer): TJsonValue; overload; //for both
    function Get(const Name: String): TJsonValue; overload; //for JsonObject

    //for JsonArray
    function Put(const Value: TJsonEmpty): TJsonValue; overload;
    function Put(const Value: TJsonNull): TJsonValue; overload;
    function Put(const Value: Boolean): TJsonValue; overload;
    function Put(const Value: Integer): TJsonValue; overload;
    function Put(const Value: Extended): TJsonValue; overload;
    function Put(const Value: String): TJsonValue; overload;
    function Put(const Value: TJsonArray): TJsonValue; overload;
    function Put(const Value: TJsonObject): TJsonValue; overload;
    function Put(const Value: TJsonValue): TJsonValue; overload;
    function Put(const Value: TJson): TJsonValue; overload;

    //for JsonObject
    function Put(const Name: String; const Value: TJsonEmpty): TJsonValue; overload;
    function Put(const Name: String; const Value: TJsonNull): TJsonValue; overload;
    function Put(const Name: String; const Value: Boolean): TJsonValue; overload;
    function Put(const Name: String; const Value: Integer): TJsonValue; overload;
    function Put(const Name: String; const Value: Extended): TJsonValue; overload;
    function Put(const Name: String; const Value: String): TJsonValue; overload;
    function Put(const Name: String; const Value: TJsonArray): TJsonValue; overload;
    function Put(const Name: String; const Value: TJsonObject): TJsonValue; overload;
    function Put(const Name: String; const Value: TJsonValue): TJsonValue; overload;
    function Put(const Name: String; const Value: TJson): TJsonValue; overload;
    function Put(const Value: TJsonPair): TJsonValue; overload;

  public
    property StructType: TJsonStructType read FStructType;
    property JsonObject: TJsonObject read GetJsonObject;
    property JsonArray: TJsonArray read GetJsonArray;

    property Count: Integer read GetCount;
    property Values[Name: String]: TJsonValue read GetValues; default; //for JsonObject
  end;


function FixedFloatToStr(const Value: Extended): string;
function FixedTryStrToFloat(const S: string; out Value: Extended): Boolean;
function FixedStrToFloat(const S: string): Extended;
function JSONDateToString(aDate : TDateTime) : String;
function JSONStringToDate(aDate : String) : TDateTime;

{$IFDEF DCC} //Currently, this compile on FPC work only for trunck. But Trunck is broken on ARM. :(
Function __ObjectToJson(aObject : TObject) : String;
Procedure __jsonToObject(Const aJSONString : String; Var aObject : TObject);
{$ENDIF DCC} //Currently, this compile on FPC work only for trunck. But Trunck is broken on ARM. :(

Type
  TObjectDynArray = array of TObject;
  TStringDynArray = array of string;
  TIntegerDynArray = array of Integer;

Const
  GLB_JSON_STD_DECIMALSEPARATOR = '.';


implementation

Uses TypInfo,
     DateUtils;

{$REGION JsonUtils}


{$IFDEF DCC} //Currently, this compile on FPC work only for trunck. But Trunck is broken on ARM. :(
Type
  PPPTypeInfo = ^PPTypeInfo;
{$ENDIF}


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
            ZeroFillStr(SecondOf(aDate),3)+'Z';
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


{**
 * Fixed FloatToStr to convert DecimalSeparator to dot (.) decimal separator, FloatToStr returns
 * DecimalSeparator as decimal separator, but JSON uses dot (.) as decimal separator.
 *}
function GetDecimalSeparator : Char;
  {$IFDEF FPC}
var
  LFormatSettings: TFormatSettings;
  {$ENDIF}
begin
  {$IFDEF DCC}
  Result :=  FormatSettings.DecimalSeparator;
  {$ELSE}
    {$IFDEF FPC}
    LFormatSettings := DefaultFormatSettings;
    Result :=  LFormatSettings.DecimalSeparator;
    {$ELSE}
      {$IFDEF PAS2JS}
        result := '.';
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
end;


function FixedFloatToStr(const Value: Extended): string;
var
  lS: string;
begin
  lS := FloatToStr(Value);
  if GetDecimalSeparator = GLB_JSON_STD_DECIMALSEPARATOR then
  begin
    Result := LS;
  end
  else
  begin
    Result := StringReplace( lS,
                             GetDecimalSeparator,
                             GLB_JSON_STD_DECIMALSEPARATOR,
                             [rfReplaceAll]);
  end;
end;

{**
 * Fixed TryStrToFloat to convert dot (.) decimal separator to DecimalSeparator, TryStrToFloat expects
 * decimal separator to be DecimalSeparator, but JSON uses dot (.) as decimal separator.
 *}
function FixedTryStrToFloat(const S: string; out Value: Extended): Boolean;
var
  FixedS: string;
begin
  if FormatSettings.DecimalSeparator = GLB_JSON_STD_DECIMALSEPARATOR then
  begin
    Result := TryStrToFloat(S, Value);
  end
  else
  begin
    FixedS := StringReplace( S,
                             GLB_JSON_STD_DECIMALSEPARATOR,
                             FormatSettings.DecimalSeparator,
                             [rfReplaceAll]);
    Result := TryStrToFloat(FixedS, Value);
  end;
end;

{**
 * Fixed StrToFloat to convert dot (.) decimal separator to DecimalSeparator, StrToFloat expects
 * decimal separator to be DecimalSeparator, but JSON uses dot (.) as decimal separator.
 *}
function FixedStrToFloat(const S: string): Extended;
var
  FixedS: string;
begin
  if FormatSettings.DecimalSeparator = GLB_JSON_STD_DECIMALSEPARATOR then
  begin
    Result := StrToFloat(S);
  end
  else
  begin
    FixedS := StringReplace( S,
                             GLB_JSON_STD_DECIMALSEPARATOR,
                             FormatSettings.DecimalSeparator,
                             [rfReplaceAll]);
    Result := StrToFloat(FixedS);
  end;
end;

function InArray(Str : string; ary : array of String) : boolean;
var
  i: Integer;
begin
  Result := Length(ary)=0;
  for i := 0 to Length(ary) - 1 do
  begin
    if CompareText(ary[i],Str) = 0 then
    begin
      Result := True;
      break;
    end;
  end;
end;


{$IFDEF DCC} //Currently, this compile on FPC work only for trunck. But Trunck is broken on ARM. :(
function InternalObjectToJSON(Obj : Tobject; PropList : array of String; WriteClass : boolean = false) : String; overload;
const lcst_exceptheader = 'ObjectToJson : ';
var
  pl : PPropList;
  iCnt : integer;
  i: Integer;
  sVal : string;
  o : TObject;
  //dyn array.
  lTypeData: PTypeData;
  {$IFDEF FPC}
  P : Pointer;
  lTypeInfoFPC : PTypeInfo;
  {$ENDIF}
  lTypeInfo: PPTypeInfo;
  lpTypeInfo: PPPTypeInfo;
  j : integeR;
  arrobj : TObjectDynArray;
  arrstr : TStringDynArray;
  arrint : TIntegerDynArray;
  jc : Integer;
  jcs : String;

  js : TJson;
  lsName : String;

    Procedure RT;
    begin
      raise Exception.Create(lcst_exceptheader + 'Type must be implemented');
    end;


begin
  if not Assigned(obj) then
    raise Exception.Create(lcst_exceptheader + 'Input object is null');

  iCnt := GetPropList(Obj, pl);
  js :=  TJSon.Create;
  try
    Result := '{' {$IFDEF LINEBREAKJSONFORMAT}+ sLineBreak {$ENDIF};
    if WriteClass then
    begin
      Result := Result+'"class" : "'+js.Encode(obj.ClassName)+'"';
    end;
    for i := 0 to iCnt-1 do
    begin
      lsName := String(pl[i]^.Name);
      if not InArray(lsName, PropList) then
        Continue;
      sVal := '';
      case pl[i]^.PropType^.Kind of
        tkInteger: sVal := IntToStr(GetOrdProp(obj,pl[i]));
        tkFloat  :
        begin
          if pl[i]^.PropType^.Name = 'TDateTime' then
            sVal := JSONDateToString(GetFloatProp(obj,pl[i]))
          else if pl[i]^.PropType^.Name = 'TDate' then
            sVal := JSONDateToString(GetFloatProp(obj,pl[i]))
          else if pl[i]^.PropType^.Name = 'TTime' then
            sVal := JSONDateToString(GetFloatProp(obj,pl[i]))
          else
            sVal := FixedFloatToStr(GetFloatProp(obj,pl[i]));
        end;
        tkInt64  : sVal := IntToStr(GetInt64Prop(obj,pl[i]));

        tkChar   : sVal := '"'+js.Encode(Char(GetOrdProp(obj,pl[i])))+'"';
        {$IFDEF FPC}
        tkAString,
        {$ENDIF}
        tkLString,
        tkString,
        tkUString: sVal := '"'+js.Encode(GetStrProp(obj,pl[i]))+'"';
        tkWChar  : sVal := '"'+js.Encode(WideChar(GetOrdProp(obj,pl[i])))+'"';
        tkWString: sVal := '"'+js.Encode(GetWideStrProp(obj,pl[i]))+'"';
        tkEnumeration:
        begin
          sVal := GetEnumProp(obj,lsName);
          sVal := '"'+js.Encode(IntToStr(GetEnumValue(pl[i]^.PropType{$IFNDEF FPC}^{$ENDIF},sVal)))+'"';  //GetEnumValue(pl[i]^.PropType^,GetEnumProp(obj,pl[i].Name))
        end;
        tkClass:
        begin
          o := GetObjectProp(Obj,pl[i]);
          if o is TObject then
            sVal := InternalObjectToJSON(TObject(o),PropList)
          else
            Continue;
        end;
        tkDynArray :
        begin
          sVal := '[ ';
          jcs :=',';

          lTypeData := GetTypeData(pl[i]^.PropType{$IFNDEF FPC}^{$ENDIF});
          {$IFNDEF FPC}
          lpTypeInfo :=  PPPTypeInfo(lTypeData^.DynUnitNameFld.Tail);
          lTypeInfo := lpTypeInfo^;
          case lTypeInfo^.Kind of
          {$ELSE}
          lTypeInfoFPC := lTypeData^.ElType2;
          case lTypeInfoFPC^.Kind of
            tkAString,
          {$ENDIF}
            tkUString, tkString : //Warning, take care of {$IFDEF} just upside :)
            begin
              arrstr := TStringDynArray(GetDynArrayProp(Obj, pl[i]));
              jc := Length(arrstr)-1;
              for j := 0 to Length(arrstr)-1 do
              begin
                if j=jc then
                  jcs := EmptyStr;
                sVal := sVal + js.Encode(arrstr[j]) + jcs;
              end;
            end;
            tkInteger :
            begin
              arrint := TIntegerDynArray(GetDynArrayProp(Obj, pl[i]));
              jc := Length(arrint)-1;
              for j := 0 to Length(arrint)-1 do
              begin
                if j=jc then
                  jcs := EmptyStr;
                sVal := sVal + js.Encode(IntToStr(arrint[j])) + jcs;
              end;
            end;
            tkClass :
            begin
              arrobj := TObjectDynArray(GetDynArrayProp(Obj, pl[i]));
              jc := Length(arrobj)-1;
              for j := 0 to Length(arrobj)-1 do
              begin
                if j=jc then
                  jcs := EmptyStr;
                sVal := sVal + InternalObjectToJSON(TObject(arrobj[j]),[]) + jcs;
              end;
            end;
          end;
          sVal :=sval +  ' ]';
        end;
        tkArray,
        tkUnknown,
        tkSet,
        tkMethod,
        tkVariant,
        tkRecord, //Record will not be supported because of discrepeancy between delphi and FPC for record rtti processing.
        tkInterface : RT;
      end;

      Result := Result + '"' + js.Encode(lsName)+'" : '+sVal;
      if Trim(Result) <> '{' then
      begin
        if i< icnt-1 then
        begin
            Result := Result+' , ' {$IFDEF LINEBREAKJSONFORMAT}+ sLineBreak {$ENDIF};
        end
        else
        begin
          if Trim(Result) <> '{' then
            Result := Result {$IFDEF LINEBREAKJSONFORMAT}+ sLineBreak {$ENDIF};
        end;
      end;
    end;
  finally
    FreeMem(pl);
    FreeAndNil(js);
  end;
  Result := Result+'}';
end;

Procedure InternalJsonToObject(Const aJsonString : String; Var aObject : TObject);
const lcst_exceptheader = 'JsonToObject : ';
var //Json stuffs
    lJSON : TJson;
    lJsValue : TJsonValue;
    lJsArray : TJsonArray;

    //rtti
    lpl : PPropList;
    lTypeData: PTypeData;
    {$IFDEF FPC}
    lTypeInfoFPC : PTypeInfo;
    {$ENDIF}
    lTypeInfo: PPTypeInfo;
    lpTypeInfo: PPPTypeInfo;

    //General
    lo : TObject;
    loClass : TClass;
    lDynObjArray : TObjectDynArray;
    lIntegerArray : TIntegerDynArray;
    lstringArray : TStringDynArray;
    lpc : Cardinal;
    i,j : integer;
    lsTemp, lsName : String;

    Procedure RT;
    begin
      raise Exception.Create(lcst_exceptheader + 'Type must be implemented');
    end;

begin
  Assert((assigned(aObject)));
  lJSON := TJson.Create;
  try
    lJSON.Parse(aJsonString);
    if Not(lJSON.StructType = TJsonStructType.jsObject) then
    begin
      raise Exception.Create(lcst_exceptheader + 'JSON Parser fails : Json file is not an object representation.');
    end;

    //JSON will drive by object structure.
    lpc := GetPropList(aObject, lpl);
    for i := 0 to lpc-1 do
    begin
      lsName := String(lpl[i].Name);
      lJsValue := lJSON[lsName];

      if lJsValue.IsNull then
      begin
        if lJsValue.IsEmpty then
        begin
          //JSON Porpety null, but exists.
          Continue;
        end
        else
        begin
          //Property is not in JSON,
          Continue;
        end;
      end;

      case lpl[i]^.PropType^.Kind of
        tkFloat  :
        begin
          if lJsValue.ValueType = jvString then //According to JSON, it is parhaps a date ? Rtti reconize date as float.
          begin
            lsTemp := lJSON[lsName].AsString;
            if JSONStringIsCompatibleDate(lsTemp) then
            begin
              SetFloatProp(aObject,lsName,JSONStringToDate(lsTemp));
            end
            Else
            begin
              raise Exception.Create(lcst_exceptheader + 'Incompatible type (Perhaps unknow date format) Property "'+lsName+'"');
            end;
          end
          else
          begin
            SetFloatProp(aObject,lsName,lJSON[lsName].AsNumber);
          end;
        end;
        tkInt64  : SetInt64Prop(aObject,lsName,lJSON[lsName].AsInteger);
        tkInteger: SetOrdProp(aObject,lsName,lJSON[lsName].AsInteger);
        tkLString,
        tkString,
        tkUString,
        tkChar,
        tkWChar,
        {$IFDEF FPC}
        tkAString,
        {$ENDIF}
        tkWString:
        begin
          SetStrProp(aObject,String(lsName),lJSON[String(lsName)].AsString);
        end;
        tkEnumeration: SetOrdProp(aObject,String(lsName),Integer(lJSON[lsName].AsInteger));
        tkClass:
        begin
          if (lJsValue.ValueType = TJsonValueType.jvObject) or (lJsValue.ValueType = TJsonValueType.jvNone) then
          begin
            //In jvNone case, we do nothing (JSON has not this property, but it is object which driven our build.
            if (lJsValue.ValueType = TJsonValueType.jvObject) then
            begin
              lTypeData := GetTypeData(lpl[i]^.PropType{$IFNDEF FPC}^{$ENDIF});
              loClass := lTypeData^.ClassType;
              lo := loClass.Create;
              try
                InternalJsonToObject(lJsValue.Stringify, lo);
              Except
                On E: Exception do
                  raise Exception.Create(lcst_exceptheader + '[InternalJsonToObject reentrance single object] (Property '+string(lsName)+') ' + E.Message);
              end;
              SetObjectProp(aObject,String(lpl[i]^.Name),lo);
            end;
          end
          else
          begin
            raise Exception.Create(lcst_exceptheader + 'Original JSON type not match with class type : Property "'+string(lsName)+'"');
          end;
        end;
        tkDynArray :
        begin
          if lJsValue.ValueType = TJsonValueType.jvArray then
          begin
            ljsArray := lJsValue.AsArray;
            for j := 0 to lJsArray.Count-1 do
            begin
              case lJsArray[j].ValueType of
                jvString :
                begin
                  SetLength(lstringArray,Length(lstringArray)+1);
                  lstringArray[Length(lstringArray)-1] := lJsArray[j].AsString;
                end;
                jvObject :
                begin
                  lTypeData := GetTypeData(lpl[i]^.PropType{$IFNDEF FPC}^{$ENDIF});
                  {$IFNDEF FPC}
                  //Delphi compiler : RTTI permit to get automaticaly dependance class.
                  lpTypeInfo :=  PPPTypeInfo(lTypeData^.DynUnitNameFld.Tail);
                  lTypeInfo := lpTypeInfo^;
                  if (lTypeInfo^.Kind = tkClass) then
                  begin
                    loClass := lTypeInfo^.TypeData^.ClassType;
                    //loClass := TGSJson.Configuration.GetPropertyConfiguration(lpl[i]^.Name).ItemArrayType; //do as FPC ? switch ?
                  end
                  else
                  begin
                    raise Exception.Create(lcst_exceptheader + ' Delphi Class resolving : Not object Error : Property "'+lsName+'"');
                  end;
                  {$ELSE}
                  //FPC side : first view not possible :( Use kind of marshaller config instead.
                  lTypeInfoFPC := lTypeData^.ElType2;
                  if (lTypeInfoFPC^.Kind = tkClass) then
                  begin
                    loClass := TGSJson.Configuration.GetPropertyConfiguration(lpl[i]^.Name).ItemArrayType;
                  end
                  else
                  begin
                    raise Exception.Create(lcst_exceptheader + ' FPC Class resolving : Not object Error : Property "'+lsName+'"');
                  end;
                  {$ENDIF}
                  lo := loClass.Create;
                  try
                    InternalJsonToObject(lJsArray[j].Stringify, lo);
                    SetLength(lDynObjArray,Length(lDynObjArray)+1);
                    lDynObjArray[Length(lDynObjArray)-1] := lo;
                  Except
                    On E: EXception do
                      raise Exception.Create(lcst_exceptheader +'[InternalJsonToObject reentrance] : Property "'+lsName+'" - ' + E.Message);
                  end;
                end;
                jvNumber:
                begin
                  SetLength(lIntegerArray,Length(lIntegerArray)+1);
                  lIntegerArray[Length(lIntegerArray)-1] := lJsArray[j].AsInteger;
                end
                else
                begin
                  raise Exception.Create(lcst_exceptheader + 'type not implemented or supported : Property "'+lsName+'"');
                end;
              end;
            end;
            if lJsArray.Count>0 then
            begin
              case lJsArray[0].ValueType of
              jvString : SetDynArrayProp(aObject,lsName,lstringArray);
              jvObject : SetDynArrayProp(aObject,lsName,lDynObjArray);
              jvNumber : SetDynArrayProp(aObject,lsName,lIntegerArray);
              end;
            end;
          end
          else
          begin
            //empty element.
            if Not(lJsValue.IsNull) then
            begin
              //element does not exists in JSON. error ?
              //Todo : Property like "StrictElementCorrespondaceCheck" something like that ?
              //raise Exception.Create('type Error Message');
            end;
          end;
        end;
        tkArray,
        tkUnknown,
        tkSet,
        tkMethod,
        tkVariant,
        tkRecord,
        tkInterface : RT;
      end;
    end;
  finally
    Dispose(lpl);
    FreeAndNil(lJSON);
  end;
end;

function __ObjectToJson(aObject: TObject): String;
begin
  Result := InternalObjectToJSON(aObject,[]);
end;

Procedure __jsonToObject(Const aJSONString : String; Var aObject : TObject);
begin
  InternalJsonToObject(aJSONString, aObject);
end;
{$ENDIF DCC} // Currently, this compile on FPC work only for trunck. But Trunck is broken on ARM. :(


     {$REGION}

{ TJsonBase }

function TJsonBase.AnalyzeJsonValueType(const S: String): TJsonValueType;
var
  Len: Integer;
  Number: Extended;
begin
  Result := jvNone;
  Len := Length(S);
  if Len >= 2 then
  begin
    if (S[1] = '{') and (S[Len] = '}') then Result := jvObject
    else if (S[1] = '[') and (S[Len] = ']') then Result := jvArray
    else if (S[1] = '"') and (S[Len] = '"') then Result := jvString
    else if SameText(S, 'null') then Result := jvNull
    else if SameText(S, 'true') or SameText(S, 'false') then Result := jvBoolean
    else if FixedTryStrToFloat(S, Number) then Result := jvNumber;
  end
  else if FixedTryStrToFloat(S, Number) then Result := jvNumber;
end;

constructor TJsonBase.Create(AOwner: TJsonBase);
begin
  FOwner := AOwner;
end;

function TJsonBase.Decode(const S: String): String;

  function HexValue(C: Char): Byte;
  begin
    case C of
      '0'..'9':  Result := Byte(C) - Byte('0');
      'a'..'f':  Result := (Byte(C) - Byte('a')) + 10;
      'A'..'F':  Result := (Byte(C) - Byte('A')) + 10;
      else raise Exception.Create('Illegal hexadecimal characters "' + C + '"');
    end;
  end;

var
  I: Integer;
  C: Char;
  ubuf : integer;
begin
  Result := '';
  I := 1;

  //Pure line break in json data string not allowed.
  if S.Contains(sLineBreak) then
    raise Exception.Create('CRLF not allowd in JSON String - TJsonBase.Decode');

  while I <= Length(S) do
  begin
    C := S[I];
    Inc(I);
    if C = '\' then
    begin
      C := S[I];
      Inc(I);
      case C of
        'b': Result := Result + #8;
        't': Result := Result + #9;
        'n': Result := Result + #10;
        'f': Result := Result + #12;
        'r': Result := Result + #13;
        'u':
        begin
          if not TryStrToInt('$' + Copy(S, I, 4), ubuf) then
            raise Exception.Create(format('Invalid unicode \u%s',[Copy(S, I, 4)]));
          result := result + WideChar(ubuf);
          Inc(I, 4);
        end;
        else Result := Result + C;
      end;
    end
    else Result := Result + C;
  end;
end;

destructor TJsonBase.Destroy;
begin
  inherited Destroy;
end;

function TJsonBase.Encode(const S: String): String;
var
  I, UnicodeValue : Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    case C of
      '"':Result := Result + '\' + C;
      '\': Result := Result + '\' + C;
      '/': Result := Result + '\' + C;
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
      else
      if (C < WideChar(32)) or (C > WideChar(127)) then
      begin
        Result := result + '\u';
        UnicodeValue := Ord(C);
        Result := result + lowercase(IntToHex((UnicodeValue and 61440) shr 12,1));
        Result := result + lowercase(IntToHex((UnicodeValue and 3840) shr 8,1));
        Result := result + lowercase(IntToHex((UnicodeValue and 240) shr 4,1));
        Result := result + lowercase(IntToHex((UnicodeValue and 15),1));
      end
      else
       Result := Result + C;

    end;
  end;
end;

function TJsonBase.GetOwner: TJsonBase;
begin
  Result := FOwner;
end;

function TJsonBase.GetOwnerName: String;
var
  TheOwner: TJsonBase;
begin
  Result := '';
  TheOwner := Owner;
  while True do
  begin
    if not Assigned(TheOwner) then Break
    else if TheOwner is TJsonPair then
    begin
      Result := (TheOwner as TJsonPair).Name;
      Break;
    end
    else TheOwner := TheOwner.Owner;
  end;
end;

function TJsonBase.IsJsonArray(const S: String): Boolean;
var
  Len: Integer;
begin
  Len := Length(S);
  Result := (Len >= 2) and (S[1] = '[') and (S[Len] = ']');
end;

function TJsonBase.IsJsonBoolean(const S: String): Boolean;
begin
  Result := SameText(lowercase(S), 'true') or SameText(lowercase(S), 'false');
end;

function TJsonBase.IsJsonNull(const S: String): Boolean;
begin
  Result := SameText(S, 'null');
end;

function TJsonBase.IsJsonNumber(const S: String): Boolean;
var
  Number: Extended;
begin
  Result := FixedTryStrToFloat(S, Number);
end;

function TJsonBase.IsJsonObject(const S: String): Boolean;
var
  Len: Integer;
begin
  Len := Length(S);
  Result := (Len >=2)
            and (CharInSet(S[1],['{','[']))
            and (CharInSet(S[Len],['}',']']))
            and (S[1]<>S[Len]);
end;

function TJsonBase.IsJsonString(const S: String): Boolean;
var
  Len: Integer;
begin
  Len := Length(S);
  Result := (Len >= 2) and (S[1] = '"') and (S[Len] = '"');
end;

procedure TJsonBase.RaiseAssignError(Source: TJsonBase);
var
  SourceClassName: String;
begin
  if Source is TObject then SourceClassName := Source.ClassName
  else SourceClassName := 'nil';
  RaiseError(Format('assign error: %s to %s', [SourceClassName, ClassName]));
end;

procedure TJsonBase.RaiseError(const Msg: String);
var
  S: String;
begin
  S := Format('<%s>%s', [ClassName, Msg]);
  raise Exception.Create(S);
end;

procedure TJsonBase.RaiseParseError(const JsonString: String);
begin
  RaiseError(Format('"%s" parse error: %s', [GetOwnerName, JsonString]));
end;

procedure TJsonBase.Split(const S: String; const Delimiter: Char;
  Strings: TStrings);

  function IsPairBegin(C: Char): Boolean;
  begin
    Result := (C = '{') or (C = '[') or (C = '"');
  end;

  function GetPairEnd(C: Char): Char;
  begin
    case C of
      '{': Result := '}';
      '[': Result := ']';
      '"': Result := '"';
      else Result := #0;
    end;
  end;

  function MoveToPair(P: PChar): PChar;
  var
    PairBegin, PairEnd: Char;
    C: Char;
  begin
    PairBegin := P^;
    PairEnd := GetPairEnd(PairBegin);
    Result := P;
    while Result^ <> #0 do
    begin
      Inc(Result);
      C := Result^;
      if C = PairEnd then Break
      else if (PairBegin = '"') and (C = '\') then Inc(Result)
      else if (PairBegin <> '"') and IsPairBegin(C) then Result := MoveToPair(Result);
    end;
  end;

var
  PtrBegin, PtrEnd: PChar;
  C: Char;
  StrItem: String;
begin
  PtrBegin := PChar(S);
  PtrEnd := PtrBegin;
  while PtrEnd^ <> #0 do
  begin
    C := PtrEnd^;
    if C = Delimiter then
    begin
      StrItem := Trim(Copy(PtrBegin, 1, PtrEnd - PtrBegin));
      Strings.Add(StrItem);
      PtrBegin := PtrEnd + 1;
      PtrEnd := PtrBegin;
      Continue;
    end
    else if IsPairBegin(C) then PtrEnd := MoveToPair(PtrEnd);
    Inc(PtrEnd);
  end;
  StrItem := Trim(Copy(PtrBegin, 1, PtrEnd - PtrBegin));
  if StrItem <> '' then Strings.Add(StrItem);
end;

{ TJsonValue }

procedure TJsonValue.Assign(Source: TJsonBase);
var
  Src: TJsonValue;
begin
  Clear;
  if not(Source is TJsonValue) and not(Source is TJsonObject) and not(Source is TJsonArray) then
    RaiseAssignError(Source);
  if Source is TJsonObject then
  begin
    FValueType := jvObject;
    FObjectValue := TJsonObject.Create(Self);
    FObjectValue.Assign(Source);
  end
  else if Source is TJsonArray then
  begin
    FValueType := jvArray;
    FArrayValue := TJsonArray.Create(Self);
    FArrayValue.Assign(Source);
  end
  else if Source is TJsonValue then
  begin
    Src := Source as TJsonValue;
    FValueType := Src.FValueType;
    case FValueType of
      jvNone, jvNull: ;
      jvString: FStringValue := Src.FStringValue;
      jvNumber: FNumberValue := Src.FNumberValue;
      jvBoolean: FBooleanValue := Src.FBooleanValue;
      jvObject:
        begin
          FObjectValue := TJsonObject.Create(Self);
          FObjectValue.Assign(Src.FObjectValue);
        end;
      jvArray:
        begin
          FArrayValue := TJsonArray.Create(Self);
          FArrayValue.Assign(Src.FArrayValue);
        end;
    end;
  end;
end;

procedure TJsonValue.Clear;
begin
  case FValueType of
    jvNone, jvNull: ;
    jvString: FStringValue := '';
    jvNumber: FNumberValue := 0;
    jvBoolean: FBooleanValue := False;
    jvObject:
      begin
        FObjectValue.Free;
        FObjectValue := nil;
      end;
    jvArray:
      begin
        FArrayValue.Free;
        FArrayValue := nil;
      end;
  end;
  FValueType := jvNone;
end;

constructor TJsonValue.Create(AOwner: TJsonBase);
begin
  inherited Create(AOwner);
  FStringValue := '';
  FNumberValue := 0;
  FBooleanValue := False;
  FObjectValue := nil;
  FArrayValue := nil;
  FValueType := jvNone;
end;

destructor TJsonValue.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TJsonValue.GetAsArray: TJsonArray;
begin
  if IsEmpty then
  begin
    FValueType := jvArray;
    FArrayValue := TJsonArray.Create(Self);
  end;
  if FValueType <> jvArray then RaiseValueTypeError(jvArray);
  Result := FArrayValue;
end;

function TJsonValue.GetAsBoolean: Boolean;
begin
  Result := False;
  case FValueType of
    jvNone, jvNull: Result := False;
    jvString: Result := SameText(lowercase(FStringValue), 'true');
    jvNumber: Result := (FNumberValue <> 0);
    jvBoolean: Result := FBooleanValue;
    jvObject, jvArray: RaiseValueTypeError(jvBoolean);
  end;
end;

function TJsonValue.GetAsInteger: Integer;
begin
  Result := 0;
  case FValueType of
    jvNone, jvNull: Result := 0;
    jvString: Result := Trunc(StrToInt(FStringValue));
    jvNumber: Result := Trunc(FNumberValue);
    jvBoolean: Result := Ord(FBooleanValue);
    jvObject, jvArray: RaiseValueTypeError(jvNumber);
  end;
end;

function TJsonValue.GetAsNumber: Extended;
begin
  Result := 0;
  case FValueType of
    jvNone, jvNull: Result := 0;
    jvString: Result := FixedStrToFloat(FStringValue);
    jvNumber: Result := FNumberValue;
    jvBoolean: Result := Ord(FBooleanValue);
    jvObject, jvArray: RaiseValueTypeError(jvNumber);
  end;
end;

function TJsonValue.GetAsObject: TJsonObject;
begin
  if IsEmpty then
  begin
    FValueType := jvObject;
    FObjectValue := TJsonObject.Create(Self);
  end;
  if FValueType <> jvObject then RaiseValueTypeError(jvObject);
  Result := FObjectValue;
end;

function TJsonValue.GetAsString: String;
const
  BooleanStr: array[Boolean] of String = ('false', 'true');
begin
  Result := '';
  case FValueType of
    jvNone, jvNull: Result := '';
    jvString: Result := FStringValue;
    jvNumber: Result := FixedFloatToStr(FNumberValue);
    jvBoolean: Result := BooleanStr[FBooleanValue];
    jvObject, jvArray: RaiseValueTypeError(jvString);
  end;
end;

function TJsonValue.GetIsEmpty: Boolean;
begin
  Result := (FValueType = jvNone);
end;

function TJsonValue.GetIsNull: Boolean;
begin
  Result := (FValueType = jvNull);
end;

procedure TJsonValue.Parse(JsonString: String);
begin
  Clear;
  FValueType := AnalyzeJsonValueType(JsonString);
  case FValueType of
    jvNone: RaiseParseError(JsonString);
    jvNull: ;
    jvString: FStringValue := Decode(Copy(JsonString, 2, Length(JsonString) - 2));
    jvNumber: FNumberValue := FixedStrToFloat(JsonString);
    jvBoolean: FBooleanValue := SameText(JsonString, 'true');
    jvObject:
      begin
        FObjectValue := TJsonObject.Create(Self);
        FObjectValue.Parse(JsonString);
      end;
    jvArray:
      begin
        FArrayValue := TJsonArray.Create(Self);
        FArrayValue.Parse(JsonString);
      end;
  end;
end;

procedure TJsonValue.RaiseValueTypeError(const AsValueType: TJsonValueType);
const
  StrJsonValueType: array[TJsonValueType] of String = ('jvNone', 'jvNull', 'jvString', 'jvNumber', 'jvBoolean', 'jvObject', 'jvArray');
var
  S: String;
begin
  S := Format('"%s" value type error: %s to %s', [GetOwnerName, StrJsonValueType[FValueType], StrJsonValueType[AsValueType]]);
  RaiseError(S);
end;

procedure TJsonValue.SetAsArray(const Value: TJsonArray);
begin
  if FValueType <> jvArray then
  begin
    Clear;
    FValueType := jvArray;
    FArrayValue := TJsonArray.Create(Self);
  end;
  FArrayValue.Assign(Value);
end;

procedure TJsonValue.SetAsBoolean(const Value: Boolean);
begin
  if FValueType <> jvBoolean then
  begin
    Clear;
    FValueType := jvBoolean;
  end;
  FBooleanValue := Value;
end;

procedure TJsonValue.SetAsInteger(const Value: Integer);
begin
  SetAsNumber(Value);
end;

procedure TJsonValue.SetAsNumber(const Value: Extended);
begin
  if FValueType <> jvNumber then
  begin
    Clear;
    FValueType := jvNumber;
  end;
  FNumberValue := Value;
end;

procedure TJsonValue.SetAsObject(const Value: TJsonObject);
begin
  if FValueType <> jvObject then
  begin
    Clear;
    FValueType := jvObject;
    FObjectValue := TJsonObject.Create(Self);
  end;
  FObjectValue.Assign(Value);
end;

procedure TJsonValue.SetAsString(const Value: String);
begin
  if FValueType <> jvString then
  begin
    Clear;
    FValueType := jvString;
  end;
  FStringValue := Value;
end;

procedure TJsonValue.SetIsEmpty(const Value: Boolean);
const
  EmptyValueType: array[Boolean] of TJsonValueType = (jvNull, jvNone);
begin
  if FValueType <> EmptyValueType[Value] then
  begin
    Clear;
    FValueType := EmptyValueType[Value];
  end;
end;

procedure TJsonValue.SetIsNull(const Value: Boolean);
const
  NullValueType: array[Boolean] of TJsonValueType = (jvNone, jvNull);
begin
  if FValueType <> NullValueType[Value] then
  begin
    Clear;
    FValueType := NullValueType[Value];
  end;
end;

function TJsonValue.Stringify: String;
const
  StrBoolean: array[Boolean] of String = ('false', 'true');
begin
  Result := '';
  case FValueType of
    jvNone, jvNull: Result := 'null';
    jvString: Result := '"' + Encode(FStringValue) + '"';
    jvNumber: Result := FixedFloatToStr(FNumberValue);
    jvBoolean :
    begin
      //VGS20230524 - Strange, the code above replaced the 3 nexts line and suddendly, hang on VA. ? VGS 20190618
      //result := strBoolean[FBooleanValue];
      result := StrBoolean[false];
      if FBooleanValue then
        Result := StrBoolean[true];
    end;
    jvObject: Result := FObjectValue.Stringify;
    jvArray: Result := FArrayValue.Stringify;
  end;
end;

{ TJsonArray }

function TJsonArray.Add: TJsonValue;
begin
  Result := TJsonValue.Create(Self);
  FList.Add(Result);
end;

procedure TJsonArray.Assign(Source: TJsonBase);
var
  Src: TJsonArray;
  I: Integer;
begin
  Clear;
  if not(Source is TJsonArray) then RaiseAssignError(Source);
  Src := Source as TJsonArray;
  for I := 0 to Src.Count - 1 do Add.Assign(Src[I]);
end;

procedure TJsonArray.Clear;
var
  I: Integer;
  Item: TJsonValue;
begin
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonValue(FList[I]);
    Item.Free;
  end;
  FList.Clear;
end;

constructor TJsonArray.Create(AOwner: TJsonBase);
begin
  inherited Create(AOwner);
  FList := TList.Create;
end;

procedure TJsonArray.Delete(const Index: Integer);
var
  Item: TJsonValue;
begin
  Item := TJsonValue(FList[Index]);
  Item.Free;
  FList.Delete(Index);
end;

destructor TJsonArray.Destroy;
begin
  Clear;
  FList.Free;
  inherited;
end;

function TJsonArray.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TJsonArray.GetItems(Index: Integer): TJsonValue;
begin
  Result := TJsonValue(FList[Index]);
end;

function TJsonArray.Insert(const Index: Integer): TJsonValue;
begin
  Result := TJsonValue.Create(Self);
  FList.Insert(Index, Result);
end;

procedure TJsonArray.Merge(Addition: TJsonArray);
var
  I: Integer;
begin
  for I := 0 to Addition.Count - 1 do Add.Assign(Addition[I]);
end;

procedure TJsonArray.Parse(JsonString: String);
var
  I: Integer;
  S: String;
  List: TStringList;
  Item: TJsonValue;
begin
  Clear;
  JsonString := Trim(JsonString);
  if not IsJsonArray(JsonString) then RaiseParseError(JsonString);
  S := Trim(Copy(JsonString, 2, Length(JsonString) - 2));
  List := TStringList.Create;
  try
    Split(S, ',', List);
    for I := 0 to List.Count - 1 do
    begin
      Item := Add;
      Item.Parse(List[I]);
    end;
  finally
    List.Free;
  end;
end;

function TJsonArray.Put(const Value: Boolean): TJsonValue;
begin
  Result := Add;
  Result.AsBoolean := Value;
end;

function TJsonArray.Put(const Value: Integer): TJsonValue;
begin
  Result := Add;
  Result.AsInteger := Value;
end;

function TJsonArray.Put(const Value: TJsonEmpty): TJsonValue;
begin
  Result := Add;
  Result.IsEmpty := True;
end;

function TJsonArray.Put(const Value: TJsonNull): TJsonValue;
begin
  Result := Add;
  Result.IsNull := True;
end;

function TJsonArray.Put(const Value: Extended): TJsonValue;
begin
  Result := Add;
  Result.AsNumber := Value;
end;

function TJsonArray.Put(const Value: TJsonObject): TJsonValue;
begin
  Result := Add;
  Result.Assign(Value);
end;

function TJsonArray.Put(const Value: TJsonValue): TJsonValue;
begin
  Result := Add;
  Result.Assign(Value);
end;

function TJsonArray.Put(const Value: String): TJsonValue;
begin
  Result := Add;
  Result.AsString := Value;
end;

function TJsonArray.Put(const Value: TJsonArray): TJsonValue;
begin
  Result := Add;
  Result.Assign(Value);
end;

function TJsonArray.Stringify: String;
var
  I: Integer;
  Item: TJsonValue;
begin
  Result := '[';
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonValue(FList[I]);
    if I > 0 then Result := Result + ',';
    Result := Result + Item.Stringify;
  end;
  Result := Result + ']';
end;

{ TJsonPair }

procedure TJsonPair.Assign(Source: TJsonBase);
var
  Src: TJsonPair;
begin
  if not(Source is TJsonPair) then RaiseAssignError(Source);
  Src := Source as TJsonPair;
  FName := Src.FName;
  FValue.Assign(Src.FValue);
end;

constructor TJsonPair.Create(AOwner: TJsonBase; const AName: String);
begin
  inherited Create(AOwner);
  FName := AName;
  FValue := TJsonValue.Create(Self);
end;

destructor TJsonPair.Destroy;
begin
  FValue.Free;
  inherited Destroy;
end;

procedure TJsonPair.Parse(JsonString: String);
var
  List: TStringList;
  StrName: String;
begin
  List := TStringList.Create;
  try
    Split(JsonString, ':', List);
    if List.Count <> 2 then RaiseParseError(JsonString);
    StrName := List[0];
    if not IsJsonString(StrName) then RaiseParseError(StrName);
    FName := Decode(Copy(StrName, 2, Length(StrName) - 2));
    FValue.Parse(List[1]);
  finally
    List.Free;
  end;
end;

procedure TJsonPair.SetName(const Value: String);
begin
  FName := Value;
end;

function TJsonPair.Stringify: String;
begin
  Result := Format('"%s":%s', [Encode(FName), FValue.Stringify]);
end;

{ TJsonObject }

function TJsonObject.Add(const Name: String): TJsonPair;
begin
  Result := TJsonPair.Create(Self, Name);
  FList.Add(Result);
end;

procedure TJsonObject.Assign(Source: TJsonBase);
var
  Src: TJsonObject;
  I: Integer;
begin
  Clear;
  if not(Source is TJsonObject) then RaiseAssignError(Source);
  Src := Source as TJsonObject;
  for I := 0 to Src.Count - 1 do Add.Assign(Src.Pairs[I]);
end;

procedure TJsonObject.Clear;
var
  I: Integer;
  Item: TJsonPair;
begin
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonPair(FList[I]);
    Item.Free;
  end;
  FList.Clear;
end;

constructor TJsonObject.Create(AOwner: TJsonBase);
begin
  inherited Create(AOwner);
  FList := TList.Create;
end;

procedure TJsonObject.Delete(const Index: Integer);
var
  Item: TJsonPair;
begin
  Item := TJsonPair(FList[Index]);
  Item.Free;
  FList.Delete(Index);
end;

procedure TJsonObject.Delete(const Name: String);
var
  Index: Integer;
begin
  Index := Find(Name);
  if Index < 0 then RaiseError(Format('"%s" not found', [Name]));
  Delete(Index);
end;

destructor TJsonObject.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

function TJsonObject.Find(const Name: String): Integer;
var
  I: Integer;
  Pair: TJsonPair;
begin
  Result := -1;
  for I := 0 to FList.Count - 1 do
  begin
    Pair := TJsonPair(FList[I]);
    if SameText(Name, Pair.Name) then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TJsonObject.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TJsonObject.GetPairs(Index: Integer): TJsonPair;
begin
  Result := TJsonPair(FList[Index]);
end;

function TJsonObject.GetValues(Name: String): TJsonValue;
var
  Index: Integer;
  Pair: TJsonPair;
begin
  Pair := nil;
  Index := Find(Name);
  if Index < 0 then
  begin
    RaiseError(Format('%s not found', [Name]));
  end
  else Pair := TJsonPair(FList[Index]);
  Result := Pair.Value;
end;

function TJsonObject.Insert(const Index: Integer;
  const Name: String): TJsonPair;
begin
  Result := TJsonPair.Create(Self, Name);
  FList.Insert(Index, Result);
end;

procedure TJsonObject.Merge(Addition: TJsonObject);
var
  I: Integer;
begin
  for I := 0 to Addition.Count - 1 do Add.Assign(Addition.Pairs[I]);
end;

procedure TJsonObject.Parse(JsonString: String);
var
  I: Integer;
  S: String;
  List: TStringList;
  Item: TJsonPair;
  lCheckUnicity : TStringList;
begin
  Clear;
  JsonString := Trim(JsonString);
  if not IsJsonObject(JsonString) then RaiseParseError(JsonString);
  S := Trim(Copy(JsonString, 2, Length(JsonString) - 2));
  List := TStringList.Create;
  lCheckUnicity := TStringList.Create;
  lCheckUnicity.Duplicates := dupError;
  lCheckUnicity.Sorted := true;
  try
    Split(S, ',', List);
    for I := 0 to List.Count - 1 do
    begin
      Item := Add;
      Item.Parse(List[I]);
      try
        lCheckUnicity.add(Item.Name);
      Except
        On E : exception do begin
          raise Exception.Create('Error : Duplicate names ('+Item.Name+')+ - TJsonObject.Parse : object must have unique property names');
        end;
      end;
    end;
  finally
    List.Free;
    FreeAndNil(lCheckUnicity);
  end;
end;

function TJsonObject.Put(const Name: String;
  const Value: Integer): TJsonValue;
begin
  if Find(name)>-1 then
    result := TJsonPair(FList[Find(name)]).Value
  else
    Result := Add(Name).Value;
  Result.AsInteger := Value;
end;

function TJsonObject.Put(const Name: String;
  const Value: Extended): TJsonValue;
begin
  if Find(name)>-1 then
    result := TJsonPair(FList[Find(name)]).Value
  else
    Result := Add(Name).Value;
  Result.AsNumber := Value;
end;

function TJsonObject.Put(const Name: String;
  const Value: Boolean): TJsonValue;
begin
  if Find(name)>-1 then
    result := TJsonPair(FList[Find(name)]).Value
  else
    Result := Add(Name).Value;
  Result.AsBoolean := Value;
end;

function TJsonObject.Put(const Name: String;
  const Value: TJsonEmpty): TJsonValue;
begin
  if Find(name)>-1 then
    result := TJsonPair(FList[Find(name)]).Value
  else
    Result := Add(Name).Value;
  Result.IsEmpty := True;
end;

function TJsonObject.Put(const Name: String;
  const Value: TJsonNull): TJsonValue;
begin
  if Find(name)>-1 then
    result := TJsonPair(FList[Find(name)]).Value
  else
    Result := Add(Name).Value;
  Result.IsNull := True;
end;

function TJsonObject.Put(const Name: String;
  const Value: TJsonValue): TJsonValue;
begin
  if Find(name)>-1 then
    result := TJsonPair(FList[Find(name)]).Value
  else
    Result := Add(Name).Value;
  Result.Assign(Value);
end;

function TJsonObject.Put(const Value: TJsonPair): TJsonValue;
var
  Pair: TJsonPair;
begin
  Pair := Add;
  Pair.Assign(Value);
  Result := Pair.Value;
end;

function TJsonObject.Put(const Name: String;
  const Value: TJsonObject): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.Assign(Value);
end;

function TJsonObject.Put(const Name, Value: String): TJsonValue;
begin
  if Find(name)>-1 then
    result := TJsonPair(FList[Find(name)]).Value
  else
    Result := Add(Name).Value;
  Result.AsString := Value;
end;

function TJsonObject.Put(const Name: String;
  const Value: TJsonArray): TJsonValue;
begin
  Result := Add(Name).Value;
  Result.Assign(Value);
end;

function TJsonObject.Stringify: String;
var
  I: Integer;
  Item: TJsonPair;
begin
  Result := '{';
  for I := 0 to FList.Count - 1 do
  begin
    Item := TJsonPair(FList[I]);
    if I > 0 then Result := Result + ',';
    Result := Result + Item.Stringify;
  end;
  Result := Result + '}';
end;

{ TJson }

procedure TJson.Assign(Source: TJsonBase);
begin
  Clear;
  if Source is TJson then
  begin
    case (Source as TJson).FStructType of
      jsNone: ;
      jsArray:
        begin
          CreateArrayIfNone;
          FJsonArray.Assign((Source as TJson).FJsonArray);
        end;                       
      jsObject:
        begin
          CreateObjectIfNone;
          FJsonObject.Assign((Source as TJson).FJsonObject);
        end;
    end;
  end
  else if Source is TJsonArray then
  begin
    CreateArrayIfNone;
    FJsonArray.Assign(Source);
  end
  else if Source is TJsonObject then
  begin
    CreateObjectIfNone;
    FJsonObject.Assign(Source);
  end
  else if Source is TJsonValue then
  begin
    if (Source as TJsonValue).ValueType = jvArray then
    begin
      CreateArrayIfNone;
      FJsonArray.Assign((Source as TJsonValue).AsArray);
    end
    else if (Source as TJsonValue).ValueType = jvObject then
    begin
      CreateObjectIfNone;
      FJsonObject.Assign((Source as TJsonValue).AsObject);
    end
    else RaiseAssignError(Source);
  end
  else RaiseAssignError(Source);
end;

procedure TJson.CheckJsonArray;
begin
  CreateArrayIfNone;
  RaiseIfNotArray;
end;

procedure TJson.CheckJsonObject;
begin
  CreateObjectIfNone;
  RaiseIfNotObject;
end;

procedure TJson.Clear;
begin
  case FStructType of
    jsNone: ;
    jsArray:
      begin
        FJsonArray.Free;
        FJsonArray := nil;
      end;
    jsObject:
      begin
        FJsonObject.Free;
        FJsonObject := nil;
      end;
  end;
  FStructType := jsNone;
end;

constructor TJson.Create;
begin
  inherited Create(nil);
  FStructType := jsNone;
  FJsonArray := nil;
  FJsonObject := nil;
end;

procedure TJson.CreateArrayIfNone;
begin
  if FStructType = jsNone then
  begin
    FStructType := jsArray;
    FJsonArray := TJsonArray.Create(Self);
  end;
end;

procedure TJson.CreateObjectIfNone;
begin
  if FStructType = jsNone then
  begin
    FStructType := jsObject;
    FJsonObject := TJsonObject.Create(Self);
  end;
end;

procedure TJson.Delete(const Index: Integer);
begin
  RaiseIfNone;
  case FStructType of
    jsArray: FJsonArray.Delete(Index);
    jsObject: FJsonObject.Delete(Index);
  end;
end;

procedure TJson.Delete(const Name: String);
begin
  RaiseIfNotObject;
  FJsonObject.Delete(Name);
end;

destructor TJson.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TJson.Get(const Index: Integer): TJsonValue;
begin
  Result := nil;
  RaiseIfNone;
  case FStructType of
    jsArray: Result := FJsonArray.Items[Index];
    jsObject: Result := FJsonObject.Pairs[Index].Value;
  end;
end;

function TJson.Get(const Name: String): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Values[Name];
end;

function TJson.GetCount: Integer;
begin
  case FStructType of
    jsArray: Result := FJsonArray.Count;
    jsObject: Result := FJsonObject.Count;
    else Result := 0;
  end;
end;

function TJson.GetJsonArray: TJsonArray;
begin
  CheckJsonArray;
  Result := FJsonArray;
end;

function TJson.GetJsonObject: TJsonObject;
begin
  CheckJsonObject;
  Result := FJsonObject;
end;

function TJson.GetValues(Name: String): TJsonValue;
begin
  Result := Get(Name);
end;

procedure TJson.Parse(JsonString: String);
begin
  Clear;
  JsonString := Trim(JsonString);
  if IsJsonArray(JsonString) then
  begin
    CreateArrayIfNone;
    FJsonArray.Parse(JsonString);
  end
  else if IsJsonObject(JsonString) then
  begin
    CreateObjectIfNone;
    FJsonObject.Parse(JsonString);
  end
  else RaiseParseError(JsonString);
end;

function TJson.Put(const Value: Integer): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: Extended): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: Boolean): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonEmpty): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonNull): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: String): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonValue): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonObject): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Value: TJsonArray): TJsonValue;
begin
  CheckJsonArray;
  Result := FJsonArray.Put(Value);
end;

function TJson.Put(const Name: String; const Value: Integer): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: String; const Value: Extended): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: String; const Value: Boolean): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: String;
  const Value: TJsonEmpty): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: String; const Value: TJsonNull): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: String;
  const Value: TJsonValue): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Value: TJsonPair): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Value);
end;

function TJson.Put(const Name: String;
  const Value: TJsonObject): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name, Value: String): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Name: String;
  const Value: TJsonArray): TJsonValue;
begin
  CheckJsonObject;
  Result := FJsonObject.Put(Name, Value);
end;

function TJson.Put(const Value: TJson): TJsonValue;
begin
  CheckJsonArray;
  case Value.FStructType of
    jsArray: Result := Put(Value.FJsonArray);
    jsObject: Result := Put(Value.FJsonObject);
    else Result := nil;
  end;
end;

function TJson.Put(const Name: String; const Value: TJson): TJsonValue;
begin
  CheckJsonObject;
  case Value.FStructType of
    jsArray: Result := Put(Name, Value.FJsonArray);
    jsObject: Result := Put(Name, Value.FJsonObject);
    else Result := nil;
  end;
end;

procedure TJson.RaiseIfNone;
begin
  if FStructType = jsNone then RaiseError('json struct type is jsNone');
end;

procedure TJson.RaiseIfNotArray;
begin
  if FStructType <> jsArray then RaiseError('json struct type is not jsArray');
end;

procedure TJson.RaiseIfNotObject;
begin
  if FStructType <> jsObject then RaiseError('json struct type is not jsObject');
end;

function TJson.Stringify: String;
begin
  case FStructType of
    jsArray: Result := FJsonArray.Stringify;
    jsObject: Result := FJsonObject.Stringify;
    else Result := '';
  end;
end;

end.
