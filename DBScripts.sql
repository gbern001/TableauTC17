USE [TC17Demo]
GO
/****** Object:  UserDefinedFunction [dbo].[fArcGenerate]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* 
Please give credit to the author
Glenn Bernstein
glennb@funix.com
*/


CREATE FUNCTION [dbo].[fArcGenerate] (@StartDegrees float, @EndDegrees float, @InnerRadius float, @OuterRadius float)
RETURNS @ArcTable TABLE (ArcIndex int, ArcDegrees int, CosX float, SinY float)
AS
BEGIN

DECLARE @Theta float = 90

DECLARE @DegreesToRadians float  = 0.01745329251

DECLARE @CosX float
DECLARE @SinY float

DECLARE @i int = @StartDegrees
WHILE @i <= @EndDegrees
	BEGIN
		SET @CosX = COS((@Theta - @i) * @DegreesToRadians)
		SET @SinY = SIN((@Theta - @i) * @DegreesToRadians)

		INSERT INTO @ArcTable VALUES (@i, @i, @CosX * @InnerRadius, @SinY * @InnerRadius)
		INSERT INTO @ArcTable VALUES ((@EndDegrees * 2) - @i + 1, @i, @CosX * @OuterRadius, @SinY * @OuterRadius)

		SET @i = @i + 1
	END

RETURN
	
END



GO
/****** Object:  UserDefinedFunction [dbo].[fArcGeneratePercent]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE FUNCTION [dbo].[fArcGeneratePercent] (@ArcPercent float, @InnerRadius float, @OuterRadius float)
RETURNS @ArcTablePercent TABLE (ArcPercent float, ArcIndex int, ArcDegrees int, CosX float, SinY float)
AS
BEGIN

DECLARE @StartDegrees float = 0
DECLARE @EndDegrees float = 0

SET @EndDegrees = 360 * (@ArcPercent / 100)
 
INSERT @ArcTablePercent SELECT @ArcPercent, ArcIndex, ArcDegrees, CosX, SinY  FROM [dbo].[fArcGenerate] (@StartDegrees, @EndDegrees, @InnerRadius, @OuterRadius)

RETURN
	
END




GO
/****** Object:  UserDefinedFunction [dbo].[fArcGeneratePercentRange]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[fArcGeneratePercentRange] (@ArcPercentStart float, @ArcPercentEnd float, @InnerRadius float, @OuterRadius float)
RETURNS @ArcTablePercent TABLE (ArcPercent float, ArcIndex int, ArcDegrees int, CosX float, SinY float)
AS
BEGIN

DECLARE @StartDegrees float = 0
DECLARE @EndDegrees float = 0
DECLARE @ArcPercent float = @ArcPercentEnd - @ArcPercentStart

SET @StartDegrees = 360 * (@ArcPercentStart / 100)
SET @EndDegrees = 360 * (@ArcPercentEnd / 100)
 
INSERT @ArcTablePercent SELECT @ArcPercent, ArcIndex, ArcDegrees, CosX, SinY  FROM [dbo].[fArcGenerate] (@StartDegrees, @EndDegrees, @InnerRadius, @OuterRadius)

RETURN
	
END





GO
/****** Object:  UserDefinedFunction [dbo].[tvfDrawArcPercent]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Draws a circular arc starting at 12 O'clock going clockwise until the % closed is reached

Since CIRCULARSTRING requires 3 points to describe it, we have to do some math (SIN() and COS()) to find those points
and we also want to start at the top (12 o'clock) so that means we have to shift everything back 90 degreses (theta).

SELECT * FROM [dbo].tvfDrawArcPercent('Budget-Actual', 100, 1)
*/

CREATE FUNCTION [dbo].[tvfDrawArcPercent]
(
@ShapeID varchar(20),
@ArcPercent float,
@Radius float,
@Buffer float
)
RETURNS
@PolySamples TABLE
( 
ShapeID varchar(20),
ArcPercent float,
PointID int,
PointX float,
PointY float
)
AS
BEGIN


/* FOR DEBUGGING
DECLARE @ShapeID varchar(20) = 'Arc100'
DECLARE @ArcPercent float = '100'
DECLARE @Radius float = 1
DECLARE @Buffer float = 0.01
*/

DECLARE @g1 geometry;  
DECLARE @g2 geometry;

DECLARE @StartDegrees float = 0
DECLARE @EndDegrees float = 0

SET @EndDegrees = 360 * (@ArcPercent / 100)

DECLARE @Theta float = 90

DECLARE @DegreesToRadians float  = 0.01745329251
DECLARE @CosX decimal(10, 6)
DECLARE @SinY decimal(10, 6)
DECLARE @PolyString varchar(1000) = 'CIRCULARSTRING('

DECLARE @i float = @StartDegrees
SET @CosX = COS((@Theta - @i) * @DegreesToRadians)
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians)
SET @PolyString = @PolyString + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY)

SET @i = (@EndDegrees / 5) * 2
SET @CosX = COS((@Theta - @i) * @DegreesToRadians)
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians)
SET @PolyString = @PolyString + ', ' + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY)

SET @i = (@EndDegrees / 5) * 3
SET @CosX = COS((@Theta - @i) * @DegreesToRadians)
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians)
SET @PolyString = @PolyString + ', ' + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY)

SET @i = (@EndDegrees / 5) * 4
SET @CosX = COS((@Theta - @i) * @DegreesToRadians)
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians)
SET @PolyString = @PolyString + ', ' + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY)


SET @i = @EndDegrees
SET @CosX = COS((@Theta - @i) * @DegreesToRadians)
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians)
SET @PolyString = @PolyString + ', ' + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY) + ')'

SET @g1 = geometry::Parse(@PolyString);  
SET @g1 = @g1.MakeValid().STBuffer(@Buffer).STCurveToLine();

INSERT INTO @PolySamples
SELECT
@ShapeID AS ShapeID,
@ArcPercent AS ArcPercent,
PointID,
PointX * @Radius,
PointY * @Radius from [dbo].[tvfGetPolygonPoints](@g1);

RETURN;

END

GO
/****** Object:  UserDefinedFunction [dbo].[tvfDrawArcPercentPointer]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
SELECT * FROM [dbo].tvfDrawArcPercentPointer('Budget-Actual', 25, 2)

*/


CREATE FUNCTION [dbo].[tvfDrawArcPercentPointer]
(
@ShapeID varchar(20),
@ArcPercent float,
@Radius float
)
RETURNS
@PolySamples TABLE
( 
ShapeID varchar(20),
ArcPercent float,
PointID int,
PointX float,
PointY float
)
AS
BEGIN

DECLARE @g1 geometry;  
DECLARE @g2 geometry;

DECLARE @StartDegrees float = 0
DECLARE @EndDegrees float = 0

SET @EndDegrees = 360 * (@ArcPercent / 100)

DECLARE @Theta float = 90

DECLARE @DegreesToRadians float  = 0.01745329251
DECLARE @CosX decimal(10, 6)
DECLARE @SinY decimal(10, 6)
DECLARE @PolyString varchar(1000) = 'LINESTRING ('

DECLARE @i float = @EndDegrees
SET @CosX = COS((@Theta - @i) * @DegreesToRadians)
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians)

SET @PolyString = @PolyString + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY)

SET @i = @EndDegrees - 5
SET @CosX = COS((@Theta - @i) * @DegreesToRadians) * 1.05
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians) * 1.05

SET @PolyString = @PolyString + ', ' + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY)

SET @i = @EndDegrees + 5
SET @CosX = COS((@Theta - @i) * @DegreesToRadians) * 1.05
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians) * 1.05

SET @PolyString = @PolyString + ', ' + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY)

SET @i = @EndDegrees
SET @CosX = COS((@Theta - @i) * @DegreesToRadians)
SET @SinY = SIN((@Theta - @i) * @DegreesToRadians)
SET @PolyString = @PolyString + ', ' + CONVERT(VARCHAR(20), @CosX) + ' ' + CONVERT(VARCHAR(20), @SinY) + ')'

SET @g1 = geometry::Parse(@PolyString);  
SET @g1 = @g1.STBuffer(0.01).STCurveToLine();

INSERT INTO @PolySamples
SELECT
@ShapeID AS ShapeID,
@ArcPercent AS ArcPercent,
PointID,
PointX,
PointY from [dbo].[tvfGetPolygonPoints](@g1);

RETURN;

END
GO
/****** Object:  UserDefinedFunction [dbo].[tvfDrawTC17Percent]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

SELECT * FROM tvfDrawTC17Percent('T 33 Percent', 33)
*/


CREATE FUNCTION [dbo].[tvfDrawTC17Percent]
(
@ShapeID varchar(20),
@FillPercent float
)
RETURNS
@PolySamples TABLE
( 
ShapeID varchar(20),
FillPercent float,
PointID int,
PointX float,
PointY float
)
AS
BEGIN

DECLARE @letterOutline geometry;  
DECLARE @letterSolid geometry;
DECLARE @meter geometry;

DECLARE @StartLine float = 0
DECLARE @EndLine decimal(9,6)
DECLARE @EndLineChar varchar(10)

SET @StartLine = 0
SET @EndLine = 2.0 * @FillPercent / 100.0
SET @EndLineChar = CONVERT(VARCHAR(10), @EndLine)

DECLARE @PolyString varchar(1000)

-- You can change this point list to create any shape you want within the same size area
-- Or get brave and use a compound polygon to draw a real thermometer
 
DECLARE @T varchar(1000) = '(-1 2, 1 2, 1 1.5, 0.3 1.5, 0.3 0, -0.3 0, -0.3 1.5, -1 1.5, -1 2)'

SET @PolyString = 'POLYGON(' + @T + ')'

SET @letterSolid = geometry::Parse(@PolyString);  

SET @PolyString = 'LINESTRING' + @T 
SET @letterOutline = geometry::Parse(@PolyString).STBuffer(0.05)

SET @PolyString = 'POLYGON((-2 ' + @EndLineChar + ' , 2 ' + + @EndLineChar + ', 2 0, -2 0, -2 ' + @EndLineChar + '))'
SET @meter = geometry::Parse(@PolyString);

DECLARE @intersection geometry
SET @intersection = @meter.STIntersection(@letterSolid) 
SET @intersection = @intersection.STUnion(@letterOutline)

INSERT INTO @PolySamples
SELECT
@ShapeID AS ShapeID,
@FillPercent AS FillPercent,
PointID,
PointX,
PointY from [dbo].[tvfGetPolygonPoints](@intersection);

RETURN;

END

GO
/****** Object:  UserDefinedFunction [dbo].[tvfGetGeographyPoints]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		GAB
-- Create date: 03/28/17
-- Description:	Return a table of point from a polygon
-- =============================================
CREATE FUNCTION [dbo].[tvfGetGeographyPoints] 
(
@area geography 
)
RETURNS @polypoints TABLE 
(
PointID int,
Long float,
Lat float
)
AS
BEGIN
DECLARE @i INT = 1;


WHILE (@i <= @area.STNumPoints())
BEGIN
 INSERT INTO @polypoints
 SELECT @i, @area.STPointN(@i).Long AS Long, @area.STPointN(@i).Lat AS Lat;
 SET @i = @i + 1
END

INSERT INTO @polypoints
SELECT @i, @area.STPointN(1).Long AS Long, @area.STPointN(1).Lat AS Lat;

RETURN;

END


GO
/****** Object:  UserDefinedFunction [dbo].[tvfGetPolygonPoints]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		GAB
-- Create date: 03/28/17
-- Description:	Return a table of point from a polygon
-- =============================================
CREATE FUNCTION [dbo].[tvfGetPolygonPoints] 
(
@polygon geometry 
)
RETURNS @polypoints TABLE 
(
PointID int,
PointX float,
PointY float
)
AS
BEGIN
DECLARE @i INT = 1;


WHILE (@i <= @polygon.STNumPoints())
BEGIN
 INSERT INTO @polypoints
 SELECT @i, @polygon.STPointN(@i).STX AS PointX, @polygon.STPointN(@i).STY AS PointY;
 SET @i = @i + 1
END

INSERT INTO @polypoints
SELECT @i, @polygon.STPointN(1).STX AS PointX, @polygon.STPointN(1).STY AS PointY;

RETURN;

END

GO
/****** Object:  Table [dbo].[ConferenceAttendance]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferenceAttendance](
	[Year] [int] NOT NULL,
	[Attendance] [int] NOT NULL,
	[Name] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CustomShapes]    Script Date: 6/14/2017 11:26:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomShapes](
	[ShapeID] [varchar](50) NOT NULL,
	[PointID] [int] NOT NULL,
	[X] [float] NOT NULL,
	[Y] [float] NOT NULL
) ON [PRIMARY]
GO
