--Written by Aaron 02/01/2025: Purpose is to be the primary table for the Ranking data to be brought in and manipulated in Power BI. This is so we can minimize the amount of times we import from BigQuery for cost saving.

WITH RowRank AS (

    SELECT
        InstanceGUID,
        CreateTimestamp,
        ROW_NUMBER() OVER (
            PARTITION BY GUID
            ORDER BY CreateTimestamp DESC
        ) AS InstanceRowNumber,

        ROW_NUMBER() OVER (
            PARTITION BY PersonGUID
            ORDER BY CreateTimestamp DESC
        ) AS PersonRowNumber,

        LAG(InstanceRank) OVER (
            PARTITION BY PersonGUID
            ORDER BY CreateTimestamp DESC
        ) AS InstanceChangeRowNumber
    FROM `Your_Instance_Table`
)

SELECT 
    RR.InstanceRowNumber,
    RR.PersonRowNumber,
    RR.InstanceChangeRowNumber,
    AHF.*

FROM RowRank AS RR

LEFT OUTER JOIN `Your_Instance_Table` AS AHF
    ON AHF.InstanceGUID = RR.InstanceGUID
    AND AHF.CreateTimestamp = RR.CreateTimestamp

WHERE AHF.InstanceRank IS NOT NULL

ORDER BY AHF.CreateTimestamp DESC;

