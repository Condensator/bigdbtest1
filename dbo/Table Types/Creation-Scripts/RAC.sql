CREATE TYPE [dbo].[RAC] AS TABLE(
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicationType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Corporate] [bit] NOT NULL,
	[UnderwriterInstructions] [nvarchar](750) COLLATE Latin1_General_CI_AS NULL,
	[IsAllVendors] [bit] NOT NULL,
	[Replacement] [bit] NOT NULL,
	[RACProgramId] [bigint] NOT NULL,
	[ProgramId] [bigint] NULL,
	[OriginalRACId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
