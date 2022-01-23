CREATE TYPE [dbo].[ACHOperatorConfig] AS TABLE(
	[Destination] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DestName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Origin] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxID] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[SEC] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OrigDFIID] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ACHOperatorname] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Currencyname] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[FileFormat] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LastFileCreationNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
