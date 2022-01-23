CREATE TYPE [dbo].[QueryProfile] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExtractionFormat] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[DbConnectionStringKey] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
