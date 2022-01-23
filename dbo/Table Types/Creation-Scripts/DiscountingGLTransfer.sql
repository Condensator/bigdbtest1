CREATE TYPE [dbo].[DiscountingGLTransfer] AS TABLE(
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLTransferType] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[IsGLExportRequired] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
