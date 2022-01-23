CREATE TYPE [dbo].[VendorProgramAddendum] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Date1] [date] NULL,
	[Date2] [date] NULL,
	[Comment1] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Amount1_Amount] [decimal](16, 2) NOT NULL,
	[Amount1_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount2_Amount] [decimal](16, 2) NOT NULL,
	[Amount2_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Percentage1] [decimal](5, 2) NULL,
	[Number1] [bigint] NULL,
	[Flag1] [bit] NOT NULL,
	[VendorProgramAddendumTypeId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
