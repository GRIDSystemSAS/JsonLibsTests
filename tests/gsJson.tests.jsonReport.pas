///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gsJson.tests.jsonReport;

interface

uses
  DUnitX.TestFramework;

procedure GenerateJsonReport(const AResults: IRunResults; const AFileName: string);
procedure PrettyPrintReport(const AFileName: string);

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.TimeSpan,
  DUnitX.FixtureResult,
  DUnitX.TestResult,
  gs.Json;

type
  TBackendInfo = record
    Name: string;
    FactoryId: string;
    Pass: Integer;
    Fail: Integer;
    Error: Integer;
    Total: Integer;
    Score: Double;
    Time: Double;
    ShortFailDescList: string;
  end;

function GetFactoryId(const ABackendName: string): string;
const
  CMap: array[0..18] of array[0..1] of string = (
    ('gsJson',              'gsjson'),
    ('beroJson',            'berojson'),
    ('xSuperObject',        'xsuperobject'),
    ('dwsJson',             'dwsjson'),
    ('chimera',             'chimera'),
    ('embarcaderoDelphiJson','embarcaderoDelphiJson'),
    ('easyJson',            'easyjson'),
    ('lkJson',              'lkjson'),
    ('grijjyBson',          'grijjybson'),
    ('vsoftYaml',           'vsoftyaml'),
    ('myJson',              'myjson'),
    ('dynamicDataObjects',  'dynamicdataobjects'),
    ('neslibJson',          'neslibjson'),
    ('mormot2',              'mormot2'),
    ('mcJson',              'mcjson'),
    ('superObject',         'superobject'),
    ('jdo',                 'jdo'),
    ('json4Delphi',         'json4delphi'),
    ('jsonDoc',             'jsondoc')
  );
begin
  for var i := Low(CMap) to High(CMap) do
    if SameText(ABackendName, CMap[i][0]) then
      Exit(CMap[i][1]);
  Result := LowerCase(ABackendName);
end;

function ExtractBackendName(const AFixtureName: string): string;
var
  p1, p2: Integer;
begin
  Result := '';
  p1 := Pos('TgsJson_', AFixtureName);
  if p1 = 0 then
    Exit;
  p1 := p1 + Length('TgsJson_');
  p2 := Pos('_TestProject', AFixtureName);
  if p2 = 0 then
    Exit;
  Result := Copy(AFixtureName, p1, p2 - p1);
end;

procedure CollectFixtureLeaves(const AFixture: IFixtureResult;
  var AList: TList<TBackendInfo>);
var
  backendName: string;
  info: TBackendInfo;
  seen: TStringList;
  child: IFixtureResult;
begin
  backendName := ExtractBackendName(AFixture.Name);
  if backendName <> '' then
  begin
    AFixture.Reduce;
    info.Name := backendName;
    info.FactoryId := GetFactoryId(backendName);
    info.Pass := AFixture.PassCount;
    info.Fail := AFixture.FailureCount;
    info.Error := AFixture.ErrorCount;
    info.Total := info.Pass + info.Fail + info.Error;
    if info.Total > 0 then
      info.Score := info.Pass / info.Total * 100.0
    else
      info.Score := 0;
    info.Time := AFixture.Duration.TotalSeconds;

    // Collect unique fail/error test names
    seen := TStringList.Create;
    try
      seen.Duplicates := dupIgnore;
      seen.Sorted := True;
      for var f in AFixture.Failures do
        seen.Add(f.Test.Name);
      for var e in AFixture.Errors do
        seen.Add(e.Test.Name);
      info.ShortFailDescList := '';
      for var k := 0 to seen.Count - 1 do
      begin
        if info.ShortFailDescList <> '' then
          info.ShortFailDescList := info.ShortFailDescList + ', ';
        info.ShortFailDescList := info.ShortFailDescList + seen[k];
      end;
    finally
      seen.Free;
    end;
    AList.Add(info);
  end
  else
  begin
    for child in AFixture.Children do
      CollectFixtureLeaves(child, AList);
  end;
end;

procedure GenerateJsonReport(const AResults: IRunResults; const AFileName: string);
var
  root, metadata, colDesc, testTypes, summary, backendsArr, bObj: igsJson;
  backends: TList<TBackendInfo>;
  totalPass, totalFail, totalError, totalTests: Integer;
  totalTime, successRate: Double;
begin
  backends := TList<TBackendInfo>.Create;
  try
    for var fixtureResult in AResults.FixtureResults do
      CollectFixtureLeaves(fixtureResult, backends);

    backends.Sort(TComparer<TBackendInfo>.Construct(
      function(const A, B: TBackendInfo): Integer
      begin
        if A.Score > B.Score then
          Result := -1
        else if A.Score < B.Score then
          Result := 1
        else
          Result := CompareText(A.Name, B.Name);
      end));

    totalPass := 0;
    totalFail := 0;
    totalError := 0;
    totalTime := 0;
    for var i := 0 to backends.Count - 1 do
    begin
      totalPass := totalPass + backends[i].Pass;
      totalFail := totalFail + backends[i].Fail;
      totalError := totalError + backends[i].Error;
      totalTime := totalTime + backends[i].Time;
    end;
    totalTests := totalPass + totalFail + totalError;
    if totalTests > 0 then
      successRate := totalPass / totalTests * 100.0
    else
      successRate := 0;

    root := createJson('gsjson');

    metadata := createJson('gsjson');
    metadata
      .put('project', 'GS-Core JSON Module')
      .put('author', 'Vincent Gsell')
      .put('description', 'igsJson - Universal JSON interface for Delphi with pluggable backends')
      .put('generatedAt', JSONDateToString(Now))
      .put('totalBackends', backends.Count)
      .put('testsPerBackend', AResults.TestCount div backends.Count)
      .put('testOrigin', 'DUnitX RFC 8259 compliance test suite');

    colDesc := createJson('gsjson');
    colDesc
      .put('name', 'Backend display name (class fixture name)')
      .put('factoryId', 'Factory identifier used with createJson()')
      .put('pass', 'Number of tests that passed successfully')
      .put('fail', 'Tests that ran but Assert conditions were not met (wrong result)')
      .put('error', 'Tests that crashed with an unhandled exception (Access Violation, etc.)')
      .put('total', 'Total tests executed for this backend')
      .put('score', 'Pass percentage (pass/total * 100)')
      .put('time', 'Total execution time in seconds for all tests of this backend')
      .put('shortFailDescList', 'Comma-separated list of failed and errored test names');
    metadata.put('columnDescriptions', colDesc);

    testTypes := createJson('gsjson');
    testTypes
      .put('strict', 'Tests that MUST pass per RFC 8259. Failure = bug in wrapper or library limitation.')
      .put('permissive', 'Tests where the RFC says SHOULD (not MUST). Parser may accept or reject. Always passes, but logs a WARNING if non-conforming. Does NOT count as failure.');
    metadata.put('testTypes', testTypes);

    root.put('metadata', metadata);

    summary := createJson('gsjson');
    summary
      .put('totalTests', totalTests)
      .put('totalPassed', totalPass)
      .put('totalFailed', totalFail)
      .put('totalErrored', totalError)
      .put('successRate', Round(successRate * 10) / 10.0)
      .put('totalTime', Round(totalTime * 1000) / 1000.0);
    root.put('summary', summary);

    backendsArr := createJson('gsjson');
    backendsArr.put([]);
    for var i := 0 to backends.Count - 1 do
    begin
      bObj := createJson('gsjson');
      bObj
        .put('name', backends[i].Name)
        .put('factoryId', backends[i].FactoryId)
        .put('pass', backends[i].Pass)
        .put('fail', backends[i].Fail)
        .put('error', backends[i].Error)
        .put('total', backends[i].Total)
        .put('score', Round(backends[i].Score * 10) / 10.0)
        .put('time', Round(backends[i].Time * 1000) / 1000.0)
        .put('shortFailDescList', backends[i].ShortFailDescList);
      backendsArr.add(bObj);
    end;
    root.put('backends', backendsArr);

    TFile.WriteAllText(AFileName, root.stringify, TEncoding.UTF8);
  finally
    backends.Free;
  end;
end;

procedure PrettyPrintReport(const AFileName: string);
var
  json, summary, backendsArr, b: igsJson;
  content: string;
  name, factoryId: string;
  pass, fail, err, total: Integer;
  score, time: Double;
  totalTests, totalPass, totalFail, totalErr: Integer;
  totalTime, successRate: Double;
  line: string;
const
  SEP = '+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+';
  HDR = '| #  |  Backend              | Factory ID            | Pass | Fail | Error | Total | Score  |  Time  |';
begin
  if not TFile.Exists(AFileName) then
  begin
    System.Writeln('Error: JSON report file not found: ' + AFileName);
    Exit;
  end;

  content := TFile.ReadAllText(AFileName, TEncoding.UTF8);
  json := createJson('gsjson');
  json.parse(content);

  // Summary
  json.get('summary', summary);
  summary.get('totalTests', totalTests);
  summary.get('totalPassed', totalPass);
  summary.get('totalFailed', totalFail);
  summary.get('totalErrored', totalErr);
  summary.get('successRate', successRate);
  summary.get('totalTime', totalTime);

  System.Writeln;
  System.Writeln('  igsJson - RFC 8259 Compliance Test Results');
  System.Writeln('  ==========================================');
  System.Writeln;

  // Table
  System.Writeln(SEP);
  System.Writeln(HDR);
  System.Writeln(SEP);

  json.get('backends', backendsArr);
  for var i := 0 to backendsArr.jsonElementCount - 1 do
  begin
    backendsArr.get(i, b);
    b.get('name', name);
    b.get('factoryId', factoryId);
    b.get('pass', pass);
    b.get('fail', fail);
    b.get('error', err);
    b.get('total', total);
    b.get('score', score);
    b.get('time', time);

    line := Format('| %2d | %-21s | %-21s | %4d | %4d | %5d | %5d | %5.1f%% | %5.3fs |',
      [i+1, name, factoryId, pass, fail, err, total, score, time]);
    System.Writeln(line);
  end;

  System.Writeln(SEP);

  // Summary line
  line := Format('| %-2s | %-21s | %-21s | %4d | %4d | %5d | %5d | %5.1f%% | %5.3fs |',
    ['', 'TOTAL', '', totalPass, totalFail, totalErr, totalTests, successRate, totalTime]);
  System.Writeln(line);
  System.Writeln(SEP);
  System.Writeln;
end;

end.
