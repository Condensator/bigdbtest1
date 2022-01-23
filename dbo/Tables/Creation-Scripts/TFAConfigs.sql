SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TFAConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OTPAlogorithim] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPType] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[ClientKeyLength] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPLength] [int] NOT NULL,
	[FailureCounter] [int] NOT NULL,
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
