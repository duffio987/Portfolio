DECLARE @EarthRadiusMiles DECIMAL(18,10) = 3959.0;

WITH
  CusPref AS
  (
    SELECT
      C.Customer_ID,
      C.First_Name,
      C.Last_Name,
      U.latitude    AS CustLat,
      U.longitude   AS CustLon,
      TRIM(Pref.value)   AS Cruise_Preference,
      Pref.ordinal      AS PrefOrder
    FROM dbo.CruiseCustomers AS C
    CROSS APPLY 
      STRING_SPLIT(C.Cruise_Preference, ',', 1) AS Pref

    JOIN dbo.uszips    AS U
      ON U.Zip_Code = C.zip_code
    WHERE Pref.ordinal <= 3
  )

SELECT
  CPR.Customer_ID,
  CPR.First_Name,
  CPR.Last_Name,
  CPR.Cruise_Preference,
  TP.PortCity,
  TP.PortState,
  TP.PortCountry,
  TP.DistanceMiles AS DistanceToPortInMiles,
  TA.AirportName,
  TA.AirportCode,
  TA.DistanceMiles AS DistanceToAirportInMiles,
  CASE 
    WHEN TP.DistanceMiles < 250 THEN 'Rental Car' 
    ELSE TA.AirportCode 
  END AS TransportationMode
FROM CusPref AS CPR

-- find *the* nearest port that matches their preference
CROSS APPLY

(
  SELECT TOP 1
    P.City                AS PortCity,
    P.State_Province_Code AS PortState,
    P.Country_Code        AS PortCountry,
    -- Haversine:
    @EarthRadiusMiles 
      * ACOS(COS(RADIANS(CPR.CustLat)) * COS(RADIANS(P.Latitude)) * COS(RADIANS(P.Longitude) - RADIANS(CPR.CustLon)) + SIN(RADIANS(CPR.CustLat)) * SIN(RADIANS(P.Latitude))
      ) AS DistanceMiles
  FROM dbo.[Cruise Port Geospacial Data] AS P
  CROSS APPLY 
    STRING_SPLIT(P.Cruise_Preferences, ',', 1) AS SP
  WHERE TRIM(SP.value) = CPR.Cruise_Preference
    AND P.Latitude  IS NOT NULL
    AND P.Longitude IS NOT NULL
  ORDER BY DistanceMiles
) AS TP

-- find the *one* nearest airport to that customer
CROSS APPLY
(
  SELECT TOP 1
    A.AIRPORT AS AirportName,
    A.IATA AS AirportCode,
        -- Haversine:
    @EarthRadiusMiles 
    * ACOS(COS(RADIANS(CPR.CustLat)) * COS(RADIANS(A.LATITUDE)) * COS(RADIANS(A.LONGITUDE) - RADIANS(CPR.CustLon)) + SIN(RADIANS(CPR.CustLat)) * SIN(RADIANS(A.LATITUDE))
        ) AS DistanceMiles

  FROM dbo.usaairports AS A

  WHERE A.LATITUDE  IS NOT NULL
    AND A.LONGITUDE IS NOT NULL

  ORDER BY DistanceMiles

) AS TA

ORDER BY
  CPR.Customer_ID,
  CPR.PrefOrder;