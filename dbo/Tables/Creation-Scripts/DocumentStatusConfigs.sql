SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentStatusConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SystemStatus] [nvarchar](27) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicableForInDoc] [bit] NOT NULL,
	[ApplicableForOutDoc] [bit] NOT NULL,
	[IsException] [bit] NOT NULL,
	[VerifyAttachment] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[IsEnd] [bit] NOT NULL,
	[IsMandatory] [bit] NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[SequenceNumber] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
