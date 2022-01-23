CREATE TYPE [dbo].[AutoPayoffTemplate] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ThresholdDaysOption] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[ThresholdDays] [int] NULL,
	[ActivatePayoffQuote] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PayoffTemplateId] [bigint] NOT NULL,
	[PayoffTemplateTerminationTypeConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
