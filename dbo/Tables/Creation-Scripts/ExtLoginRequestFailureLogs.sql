SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExtLoginRequestFailureLogs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Request] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginRequest] [bit] NOT NULL,
	[HeaderKey] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UserName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PortalName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginStatus] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[ErrorMessage] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
