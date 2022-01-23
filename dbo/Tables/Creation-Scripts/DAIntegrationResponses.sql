SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DAIntegrationResponses](
	[UniqueId] [uniqueidentifier] NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EGN_CT] [varbinary](64) NULL,
	[NationalId_CT] [varbinary](64) NULL,
	[Reports] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[XMLResponse_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[XMLResponse_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[XMLResponse_Content] [varbinary](82) NULL,
	[ExceptionMessage] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
